import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/repositories/reminder_policy_repository.dart';
import 'package:baby_tracker/domain/services/feed_reminder_surface_service.dart';
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
  int scheduleCalls = 0;
  int cancelCalls = 0;
  bool hasPendingFeedReminderValue = false;

  @override
  Future<DateTime> scheduleFeedReminder(DateTime triggerAt) async {
    scheduleCalls += 1;
    lastTriggerAt = triggerAt;
    hasPendingFeedReminderValue = true;
    return triggerAt;
  }

  @override
  Future<void> cancelFeedReminder() async {
    cancelCalls += 1;
    hasPendingFeedReminderValue = false;
  }

  @override
  Future<bool> hasPendingFeedReminder() async {
    return hasPendingFeedReminderValue;
  }
}

class _FakeFeedReminderSurfaceService implements FeedReminderSurfaceService {
  int initializeCalls = 0;
  int hideCalls = 0;
  final List<FeedReminderSurfaceModel> shown = <FeedReminderSurfaceModel>[];

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<void> hide() async {
    hideCalls += 1;
  }

  @override
  Future<void> showOrUpdate(FeedReminderSurfaceModel model) async {
    shown.add(model);
  }
}

class _FakeReminderPolicyRepository implements ReminderPolicyRepository {
  _FakeReminderPolicyRepository({
    this.currentPolicy = const ReminderPolicy(intervalHours: 4),
  });

  ReminderPolicy currentPolicy;
  ReminderPolicy? upsertedPolicy;
  int currentCalls = 0;
  int upsertCalls = 0;

  @override
  Future<ReminderPolicy> getPolicy() async {
    currentCalls += 1;
    return currentPolicy;
  }

  @override
  Future<ReminderPolicy> upsertPolicy(ReminderPolicy policy) async {
    upsertCalls += 1;
    upsertedPolicy = policy;
    currentPolicy = policy;
    return policy;
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
      final surfaceService = _FakeFeedReminderSurfaceService();
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
        reminderSurfaceService: surfaceService,
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
      expect(surfaceService.hideCalls, 0);
      expect(surfaceService.shown, hasLength(1));
      expect(
        surfaceService.shown.single.quickActionDeepLink,
        'walnie://quick-add/voice-feed',
      );
      expect(
        surfaceService.shown.single.feedMethod,
        FeedMethod.bottleBreastmilk,
      );
      expect(surfaceService.shown.single.feedAmountMl, 55);
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
        reminderSurfaceService: _FakeFeedReminderSurfaceService(),
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

  test(
    'scheduleNextFromLatestFeed hides reminder surface when no latest feed',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_interval_hours': 3,
        'reminder_next_trigger_iso': '2026-02-20T23:15:00.000',
      });
      final preferences = await SharedPreferences.getInstance();
      final notificationService = _FakeLocalNotificationService();
      final surfaceService = _FakeFeedReminderSurfaceService();
      final service = ReminderServiceImpl(
        eventRepository: _FakeEventRepository(),
        sharedPreferences: preferences,
        notificationService: notificationService,
        reminderSurfaceService: surfaceService,
      );

      await service.scheduleNextFromLatestFeed();

      expect(notificationService.cancelCalls, 1);
      expect(surfaceService.hideCalls, 1);
      expect(surfaceService.shown, isEmpty);
      expect(await service.nextTriggerTime(), isNull);
    },
  );

  test('currentPolicy reads remote policy and caches locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reminder_interval_hours': 3,
    });
    final preferences = await SharedPreferences.getInstance();
    final remoteRepository = _FakeReminderPolicyRepository(
      currentPolicy: const ReminderPolicy(intervalHours: 5),
    );
    final service = ReminderServiceImpl(
      eventRepository: _FakeEventRepository(),
      sharedPreferences: preferences,
      notificationService: _FakeLocalNotificationService(),
      reminderSurfaceService: _FakeFeedReminderSurfaceService(),
      reminderPolicyRepository: remoteRepository,
    );

    final policy = await service.currentPolicy();

    expect(policy.intervalHours, 5);
    expect(remoteRepository.currentCalls, 1);
    expect(preferences.getInt('reminder_interval_hours'), 5);
  });

  test('upsertPolicy syncs to remote policy repository', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reminder_interval_hours': 3,
    });
    final preferences = await SharedPreferences.getInstance();
    final remoteRepository = _FakeReminderPolicyRepository();
    final service = ReminderServiceImpl(
      eventRepository: _FakeEventRepository(),
      sharedPreferences: preferences,
      notificationService: _FakeLocalNotificationService(),
      reminderSurfaceService: _FakeFeedReminderSurfaceService(),
      reminderPolicyRepository: remoteRepository,
    );

    await service.upsertPolicy(const ReminderPolicy(intervalHours: 6));

    expect(preferences.getInt('reminder_interval_hours'), 6);
    expect(remoteRepository.upsertCalls, 1);
    expect(remoteRepository.upsertedPolicy?.intervalHours, 6);
  });

  test(
    'overdue reminder should not be repeatedly rescheduled for unchanged latest feed',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_interval_hours': 3,
      });
      final preferences = await SharedPreferences.getInstance();
      final notificationService = _FakeLocalNotificationService();
      final service = ReminderServiceImpl(
        eventRepository: _FakeEventRepository(
          latestFeed: BabyEvent(
            id: 'feed-overdue',
            type: EventType.feed,
            occurredAt: DateTime.now().subtract(const Duration(hours: 4)),
            feedMethod: FeedMethod.bottleBreastmilk,
            amountMl: 70,
          ),
        ),
        sharedPreferences: preferences,
        notificationService: notificationService,
        reminderSurfaceService: _FakeFeedReminderSurfaceService(),
      );

      await service.scheduleNextFromLatestFeed();
      notificationService.hasPendingFeedReminderValue = false;
      await service.scheduleNextFromLatestFeed();

      expect(notificationService.scheduleCalls, 1);
    },
  );
}
