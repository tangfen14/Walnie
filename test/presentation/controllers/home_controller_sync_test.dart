import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/get_timeline_use_case.dart';
import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({required List<BabyEvent> events}) : _events = events;

  final List<BabyEvent> _events;

  @override
  Future<void> create(BabyEvent event) async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<BabyEvent?> latest(EventType type) async {
    return _events.where((event) => event.type == type).fold<BabyEvent?>(null, (
      latest,
      current,
    ) {
      if (latest == null || current.occurredAt.isAfter(latest.occurredAt)) {
        return current;
      }
      return latest;
    });
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    return _events
        .where(
          (event) =>
              !event.occurredAt.isBefore(from) && event.occurredAt.isBefore(to),
        )
        .toList(growable: false);
  }
}

class _TrackingReminderService implements ReminderService {
  _TrackingReminderService({
    required this.initialNextTrigger,
    required this.recalculatedNextTrigger,
  }) : _nextTrigger = initialNextTrigger;

  final DateTime initialNextTrigger;
  final DateTime recalculatedNextTrigger;
  DateTime? _nextTrigger;
  int scheduleCalls = 0;

  @override
  Future<ReminderPolicy> currentPolicy() async {
    return const ReminderPolicy(intervalHours: 3);
  }

  @override
  Future<DateTime?> nextTriggerTime() async {
    return _nextTrigger;
  }

  @override
  Future<void> scheduleNextFromLatestFeed() async {
    scheduleCalls += 1;
    _nextTrigger = recalculatedNextTrigger;
  }

  @override
  Future<void> upsertPolicy(ReminderPolicy policy) async {}
}

void main() {
  test('home load recalculates next reminder before reading it', () async {
    final now = DateTime.now();
    final feedEvent = BabyEvent(
      id: 'feed-1',
      type: EventType.feed,
      occurredAt: now.subtract(const Duration(minutes: 20)),
      feedMethod: FeedMethod.bottleBreastmilk,
      amountMl: 60,
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeEventRepository(events: <BabyEvent>[feedEvent]);
    final staleTrigger = now.add(const Duration(minutes: 30));
    final refreshedTrigger = now.add(const Duration(hours: 3));
    final reminderService = _TrackingReminderService(
      initialNextTrigger: staleTrigger,
      recalculatedNextTrigger: refreshedTrigger,
    );

    final container = ProviderContainer(
      overrides: [
        getTimelineUseCaseProvider.overrideWithValue(
          GetTimelineUseCase(repository),
        ),
        getTodaySummaryUseCaseProvider.overrideWithValue(
          GetTodaySummaryUseCase(repository),
        ),
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeControllerProvider.future);

    expect(reminderService.scheduleCalls, 1);
    expect(state.nextReminderAt, refreshedTrigger);
  });
}
