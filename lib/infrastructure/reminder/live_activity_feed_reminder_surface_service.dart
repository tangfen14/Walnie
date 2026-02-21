import 'dart:io';

import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';
import 'package:baby_tracker/domain/services/feed_reminder_surface_service.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/live_activity_file.dart';

class LiveActivityFeedReminderSurfaceService
    implements FeedReminderSurfaceService {
  LiveActivityFeedReminderSurfaceService({
    required LiveActivities liveActivities,
    required String appGroupId,
  }) : _liveActivities = liveActivities,
       _appGroupId = appGroupId;

  static const String activityId = 'walnie_feed_reminder';

  final LiveActivities _liveActivities;
  final String _appGroupId;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized || !Platform.isIOS) {
      return;
    }

    await _liveActivities.init(
      appGroupId: _appGroupId,
      urlScheme: 'walnie',
      requestAndroidNotificationPermission: false,
    );
    _initialized = true;
  }

  @override
  Future<void> showOrUpdate(FeedReminderSurfaceModel model) async {
    if (!Platform.isIOS) {
      return;
    }

    await initialize();

    final supported = await _liveActivities.areActivitiesSupported();
    final enabled = await _liveActivities.areActivitiesEnabled();
    if (!supported || !enabled) {
      return;
    }

    final payload = <String, dynamic>{
      'lastFeedAtMs': model.lastFeedAt.millisecondsSinceEpoch,
      'nextReminderAtMs': model.nextReminderAt?.millisecondsSinceEpoch,
      'feedMethodKey': model.feedMethod.name,
      'feedMethodZh': _feedMethodZh(model.feedMethod),
      'feedMethodEn': _feedMethodEn(model.feedMethod),
      'quickActionUrl': model.quickActionDeepLink,
      'avatar': LiveActivityFileFromAsset.image(
        'assets/images/avatar_winnie.png',
        imageOptions: LiveActivityImageFileOptions(resizeFactor: 0.38),
      ),
    };

    await _liveActivities.createOrUpdateActivity(
      activityId,
      payload,
      removeWhenAppIsKilled: false,
      iOSEnableRemoteUpdates: false,
      staleIn: const Duration(hours: 8),
    );
  }

  @override
  Future<void> hide() async {
    if (!Platform.isIOS) {
      return;
    }
    await initialize();
    await _liveActivities.endActivity(activityId);
  }

  String _feedMethodZh(FeedMethod method) {
    switch (method) {
      case FeedMethod.breastLeft:
        return '亲喂';
      case FeedMethod.breastRight:
        return '亲喂';
      case FeedMethod.bottleFormula:
        return '奶粉喂养';
      case FeedMethod.bottleBreastmilk:
        return '瓶装母乳';
      case FeedMethod.mixed:
        return '混合喂养';
    }
  }

  String _feedMethodEn(FeedMethod method) {
    switch (method) {
      case FeedMethod.breastLeft:
        return 'Breastfeeding';
      case FeedMethod.breastRight:
        return 'Breastfeeding';
      case FeedMethod.bottleFormula:
        return 'Formula Bottle';
      case FeedMethod.bottleBreastmilk:
        return 'Bottled breast milk';
      case FeedMethod.mixed:
        return 'Mixed Feeding';
    }
  }
}
