import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:baby_tracker/infrastructure/reminder/reminder_service_impl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({this.latestFeed});

  final BabyEvent? latestFeed;

  @override
  Future<void> create(BabyEvent event) async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<BabyEvent?> latest(EventType type) async {
    if (type != EventType.feed) {
      return null;
    }
    return latestFeed;
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    return const <BabyEvent>[];
  }
}

class _FakeLocalNotificationService extends LocalNotificationService {
  _FakeLocalNotificationService() : super(FlutterLocalNotificationsPlugin());

  DateTime? lastTriggerAt;
  int cancelCalls = 0;

  @override
  Future<DateTime> scheduleFeedReminder(DateTime triggerAt) async {
    lastTriggerAt = triggerAt;
    return triggerAt;
  }

  @override
  Future<void> cancelFeedReminder() async {
    cancelCalls += 1;
  }
}

void main() {
  test(
    'scheduleNextFromLatestFeed uses wall-clock time when latest feed is utc',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_interval_hours': 3,
      });
      final preferences = await SharedPreferences.getInstance();
      final notificationService = _FakeLocalNotificationService();
      final service = ReminderServiceImpl(
        eventRepository: _FakeEventRepository(
          latestFeed: BabyEvent(
            id: 'feed-1',
            type: EventType.feed,
            occurredAt: DateTime.parse('2026-02-20T20:15:00.000Z'),
            feedMethod: FeedMethod.bottleBreastmilk,
            amountMl: 55,
          ),
        ),
        sharedPreferences: preferences,
        notificationService: notificationService,
      );

      await service.scheduleNextFromLatestFeed();

      expect(notificationService.lastTriggerAt, isNotNull);
      expect(notificationService.lastTriggerAt!.isUtc, isFalse);
      expect(notificationService.lastTriggerAt!.year, 2026);
      expect(notificationService.lastTriggerAt!.month, 2);
      expect(notificationService.lastTriggerAt!.day, 20);
      expect(notificationService.lastTriggerAt!.hour, 23);
      expect(notificationService.lastTriggerAt!.minute, 15);

      final next = await service.nextTriggerTime();
      expect(next, isNotNull);
      expect(next!.year, 2026);
      expect(next.month, 2);
      expect(next.day, 20);
      expect(next.hour, 23);
      expect(next.minute, 15);
      expect(next.isUtc, isFalse);
    },
  );

  test(
    'nextTriggerTime keeps wall-clock value from offset timestamp',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_next_trigger_iso': '2026-02-20T23:15:00.000+13:45',
      });
      final preferences = await SharedPreferences.getInstance();
      final service = ReminderServiceImpl(
        eventRepository: _FakeEventRepository(),
        sharedPreferences: preferences,
        notificationService: _FakeLocalNotificationService(),
      );

      final next = await service.nextTriggerTime();

      expect(next, isNotNull);
      expect(next!.year, 2026);
      expect(next.month, 2);
      expect(next.day, 20);
      expect(next.hour, 23);
      expect(next.minute, 15);
      expect(next.isUtc, isFalse);
    },
  );
}
