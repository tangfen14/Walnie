import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';
import 'package:baby_tracker/infrastructure/reminder/live_activity_feed_reminder_surface_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_activities/live_activities.dart';

class _FakeLiveActivities extends LiveActivities {
  int initCalls = 0;
  int supportedCalls = 0;
  int enabledCalls = 0;
  int createOrUpdateCalls = 0;
  int endCalls = 0;
  int endAllCalls = 0;
  Map<String, dynamic>? lastPayload;

  int _activeCreateCalls = 0;
  int maxConcurrentCreateCalls = 0;

  @override
  Future init({
    required String appGroupId,
    String? urlScheme,
    bool requestAndroidNotificationPermission = true,
  }) async {
    initCalls += 1;
  }

  @override
  Future<bool> areActivitiesSupported() async {
    supportedCalls += 1;
    return true;
  }

  @override
  Future<bool> areActivitiesEnabled() async {
    enabledCalls += 1;
    return true;
  }

  @override
  Future<void> createOrUpdateActivity(
    String activityId,
    Map<String, dynamic> data, {
    bool removeWhenAppIsKilled = false,
    bool iOSEnableRemoteUpdates = true,
    Duration? staleIn,
  }) async {
    createOrUpdateCalls += 1;
    lastPayload = Map<String, dynamic>.from(data);
    _activeCreateCalls += 1;
    if (_activeCreateCalls > maxConcurrentCreateCalls) {
      maxConcurrentCreateCalls = _activeCreateCalls;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _activeCreateCalls -= 1;
  }

  @override
  Future<void> endActivity(String activityId) async {
    endCalls += 1;
  }

  @override
  Future<void> endAllActivities() async {
    endAllCalls += 1;
  }
}

FeedReminderSurfaceModel _model() {
  final now = DateTime(2026, 2, 22, 8, 20);
  return FeedReminderSurfaceModel(
    lastFeedAt: now.subtract(const Duration(minutes: 15)),
    nextReminderAt: now.add(const Duration(hours: 3)),
    feedMethod: FeedMethod.bottleBreastmilk,
    feedAmountMl: 60,
    quickActionDeepLink: 'walnie://quick-add/voice-feed',
  );
}

void main() {
  test('showOrUpdate reconciles legacy activities only once', () async {
    final fake = _FakeLiveActivities();
    final service = LiveActivityFeedReminderSurfaceService(
      liveActivities: fake,
      appGroupId: 'group.com.wang.walnie.shared',
      isIOS: () => true,
    );

    await service.showOrUpdate(_model());
    await service.showOrUpdate(_model());

    expect(fake.initCalls, 1);
    expect(fake.endAllCalls, 1);
    expect(fake.createOrUpdateCalls, 2);
  });

  test(
    'showOrUpdate runs sequentially to avoid concurrent create calls',
    () async {
      final fake = _FakeLiveActivities();
      final service = LiveActivityFeedReminderSurfaceService(
        liveActivities: fake,
        appGroupId: 'group.com.wang.walnie.shared',
        isIOS: () => true,
      );

      await Future.wait(<Future<void>>[
        service.showOrUpdate(_model()),
        service.showOrUpdate(_model()),
        service.showOrUpdate(_model()),
      ]);

      expect(fake.maxConcurrentCreateCalls, 1);
      expect(fake.createOrUpdateCalls, 3);
    },
  );

  test('showOrUpdate omits null fields and avoids file payload object', () async {
    final fake = _FakeLiveActivities();
    final service = LiveActivityFeedReminderSurfaceService(
      liveActivities: fake,
      appGroupId: 'group.com.wang.walnie.shared',
      isIOS: () => true,
    );
    final now = DateTime(2026, 2, 22, 9, 0);

    await service.showOrUpdate(
      FeedReminderSurfaceModel(
        lastFeedAt: now,
        nextReminderAt: null,
        feedMethod: FeedMethod.breastLeft,
        feedAmountMl: null,
        quickActionDeepLink: 'walnie://quick-add/voice-feed',
      ),
    );

    final payload = fake.lastPayload;
    expect(payload, isNotNull);
    expect(payload!.containsKey('nextReminderAtMs'), isFalse);
    expect(payload.containsKey('feedAmountMl'), isFalse);
    expect(payload.containsKey('avatar'), isFalse);
  });
}
