import 'dart:async';

import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:baby_tracker/presentation/controllers/home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository(this.events);

  final List<BabyEvent> events;

  bool throwOnList = false;
  Completer<void>? listBarrier;

  @override
  Future<void> create(BabyEvent event) async {
    events.add(event);
  }

  @override
  Future<void> deleteById(String id) async {
    events.removeWhere((event) => event.id == id);
  }

  @override
  Future<BabyEvent?> latest(EventType type) async {
    for (var i = events.length - 1; i >= 0; i--) {
      if (events[i].type == type) {
        return events[i];
      }
    }
    return null;
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    if (listBarrier != null) {
      await listBarrier!.future;
    }
    if (throwOnList) {
      throw StateError('list failed');
    }

    final result =
        events
            .where(
              (event) =>
                  !event.occurredAt.isBefore(from) &&
                  event.occurredAt.isBefore(to),
            )
            .toList(growable: false)
          ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    return result;
  }
}

class _FakeReminderService implements ReminderService {
  int scheduleCalls = 0;
  DateTime? triggerTime;
  ReminderPolicy policy = const ReminderPolicy(intervalHours: 3);

  @override
  Future<ReminderPolicy> currentPolicy() async => policy;

  @override
  Future<DateTime?> nextTriggerTime() async => triggerTime;

  @override
  Future<void> scheduleNextFromLatestFeed() async {
    scheduleCalls += 1;
  }

  @override
  Future<void> upsertPolicy(ReminderPolicy policy) async {
    this.policy = policy;
  }
}

List<BabyEvent> _seedEvents(DateTime now) {
  return [
    BabyEvent(
      id: 'feed-1',
      type: EventType.feed,
      occurredAt: now.subtract(const Duration(minutes: 20)),
      feedMethod: FeedMethod.bottleBreastmilk,
      amountMl: 60,
    ),
    BabyEvent(
      id: 'diaper-1',
      type: EventType.diaper,
      occurredAt: now.subtract(const Duration(minutes: 30)),
    ),
    BabyEvent(
      id: 'poop-1',
      type: EventType.poop,
      occurredAt: now.subtract(const Duration(minutes: 40)),
    ),
    BabyEvent(
      id: 'pee-1',
      type: EventType.pee,
      occurredAt: now.subtract(const Duration(minutes: 50)),
    ),
    BabyEvent(
      id: 'pump-1',
      type: EventType.pump,
      occurredAt: now.subtract(const Duration(minutes: 60)),
      pumpStartAt: now.subtract(const Duration(minutes: 80)),
      pumpEndAt: now.subtract(const Duration(minutes: 60)),
      amountMl: 100,
    ),
  ];
}

void main() {
  ProviderContainer buildContainer({
    required _FakeEventRepository repository,
    required _FakeReminderService reminderService,
  }) {
    return ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(repository),
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
    );
  }

  test('setFilter updates timeline locally without AsyncLoading', () async {
    final now = DateTime.now();
    final repository = _FakeEventRepository(_seedEvents(now));
    final reminderService = _FakeReminderService();
    final container = buildContainer(
      repository: repository,
      reminderService: reminderService,
    );
    addTearDown(container.dispose);

    await container.read(homeControllerProvider.future);
    final notifier = container.read(homeControllerProvider.notifier);
    final transitions = <AsyncValue<HomeState>>[];
    final sub = container.listen<AsyncValue<HomeState>>(
      homeControllerProvider,
      (_, next) => transitions.add(next),
      fireImmediately: false,
    );
    addTearDown(sub.close);

    notifier.setFilter(EventType.feed);
    final current = container.read(homeControllerProvider);

    expect(current.isLoading, isFalse);
    expect(transitions.any((value) => value.isLoading), isFalse);
    expect(
      current.value?.timeline.every((item) => item.type == EventType.feed),
      isTrue,
    );
  });

  test('diaper filter contains diaper, poop and pee', () async {
    final now = DateTime.now();
    final repository = _FakeEventRepository(_seedEvents(now));
    final reminderService = _FakeReminderService();
    final container = buildContainer(
      repository: repository,
      reminderService: reminderService,
    );
    addTearDown(container.dispose);

    await container.read(homeControllerProvider.future);
    final notifier = container.read(homeControllerProvider.notifier);
    notifier.setFilter(EventType.diaper);

    final timeline = container.read(homeControllerProvider).value!.timeline;
    final types = timeline.map((item) => item.type).toSet();
    expect(types.contains(EventType.feed), isFalse);
    expect(types.contains(EventType.pump), isFalse);
    expect(types.contains(EventType.diaper), isTrue);
    expect(types.contains(EventType.poop), isTrue);
    expect(types.contains(EventType.pee), isTrue);
  });

  test('refreshData keeps page data and toggles timeline refreshing', () async {
    final now = DateTime.now();
    final repository = _FakeEventRepository(_seedEvents(now));
    final reminderService = _FakeReminderService();
    final container = buildContainer(
      repository: repository,
      reminderService: reminderService,
    );
    addTearDown(container.dispose);

    await container.read(homeControllerProvider.future);
    final notifier = container.read(homeControllerProvider.notifier);
    repository.listBarrier = Completer<void>();

    final refreshFuture = notifier.refreshData();
    await Future<void>.delayed(Duration.zero);
    final during = container.read(homeControllerProvider);

    expect(during.isLoading, isFalse);
    expect(during.value?.isTimelineRefreshing, isTrue);

    repository.listBarrier!.complete();
    await refreshFuture;
    final after = container.read(homeControllerProvider).value!;
    expect(after.isTimelineRefreshing, isFalse);
  });

  test('refreshData failure keeps old data and emits notice', () async {
    final now = DateTime.now();
    final repository = _FakeEventRepository(_seedEvents(now));
    final reminderService = _FakeReminderService();
    final container = buildContainer(
      repository: repository,
      reminderService: reminderService,
    );
    addTearDown(container.dispose);

    final initial = await container.read(homeControllerProvider.future);
    final notifier = container.read(homeControllerProvider.notifier);
    repository.throwOnList = true;

    await notifier.refreshData();
    final current = container.read(homeControllerProvider).value!;

    expect(
      current.timeline.map((item) => item.id),
      initial.timeline.map((item) => item.id),
    );
    expect(current.isTimelineRefreshing, isFalse);
    expect(current.uiNotice, '刷新失败，请稍后重试');
    expect(current.uiNoticeVersion, initial.uiNoticeVersion + 1);
  });

  test(
    'addEvent success but refresh failure emits save-success refresh-fail notice',
    () async {
      final now = DateTime.now();
      final repository = _FakeEventRepository(_seedEvents(now));
      final reminderService = _FakeReminderService();
      final container = buildContainer(
        repository: repository,
        reminderService: reminderService,
      );
      addTearDown(container.dispose);

      await container.read(homeControllerProvider.future);
      final notifier = container.read(homeControllerProvider.notifier);
      repository.throwOnList = true;

      await notifier.addEvent(
        BabyEvent(
          id: 'feed-new',
          type: EventType.feed,
          occurredAt: now,
          feedMethod: FeedMethod.bottleBreastmilk,
          amountMl: 70,
        ),
      );

      final current = container.read(homeControllerProvider).value!;
      expect(repository.events.any((event) => event.id == 'feed-new'), isTrue);
      expect(current.uiNotice, '保存成功，刷新失败');
    },
  );
}
