import 'package:baby_tracker/application/usecases/create_event_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  final List<BabyEvent> saved = [];

  @override
  Future<void> create(BabyEvent event) async {
    saved.add(event);
  }

  @override
  Future<BabyEvent?> latest(EventType type) async {
    for (var i = saved.length - 1; i >= 0; i--) {
      if (saved[i].type == type) {
        return saved[i];
      }
    }
    return null;
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    return saved
        .where(
          (event) =>
              !event.occurredAt.isBefore(from) && event.occurredAt.isBefore(to),
        )
        .toList(growable: false);
  }
}

class _FakeReminderService implements ReminderService {
  int scheduleCalls = 0;

  @override
  Future<ReminderPolicy> currentPolicy() async {
    return const ReminderPolicy(intervalHours: 3);
  }

  @override
  Future<DateTime?> nextTriggerTime() async {
    return null;
  }

  @override
  Future<void> scheduleNextFromLatestFeed() async {
    scheduleCalls += 1;
  }

  @override
  Future<void> upsertPolicy(ReminderPolicy policy) async {}
}

void main() {
  test('create feed event triggers reminder scheduling', () async {
    final repository = _FakeEventRepository();
    final reminder = _FakeReminderService();
    final useCase = CreateEventUseCase(
      eventRepository: repository,
      reminderService: reminder,
    );

    await useCase(
      BabyEvent(
        type: EventType.feed,
        occurredAt: DateTime.now(),
        feedMethod: FeedMethod.bottleFormula,
        amountMl: 60,
      ),
    );

    expect(repository.saved, hasLength(1));
    expect(reminder.scheduleCalls, 1);
  });

  test('create pee event does not trigger reminder scheduling', () async {
    final repository = _FakeEventRepository();
    final reminder = _FakeReminderService();
    final useCase = CreateEventUseCase(
      eventRepository: repository,
      reminderService: reminder,
    );

    await useCase(BabyEvent(type: EventType.pee, occurredAt: DateTime.now()));

    expect(repository.saved, hasLength(1));
    expect(reminder.scheduleCalls, 0);
  });
}
