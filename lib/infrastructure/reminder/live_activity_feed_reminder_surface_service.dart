import 'dart:async';
import 'dart:io';

import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';
import 'package:baby_tracker/domain/services/feed_reminder_surface_service.dart';
import 'package:live_activities/live_activities.dart';

class LiveActivityFeedReminderSurfaceService
    implements FeedReminderSurfaceService {
  LiveActivityFeedReminderSurfaceService({
    required LiveActivities liveActivities,
    required String appGroupId,
    bool Function()? isIOS,
  }) : _liveActivities = liveActivities,
       _appGroupId = appGroupId,
       _isIOS = isIOS ?? (() => Platform.isIOS);

  static const String activityId = 'walnie_feed_reminder';

  final LiveActivities _liveActivities;
  final String _appGroupId;
  final bool Function() _isIOS;
  bool _initialized = false;
  bool _didInitialReconcile = false;
  Future<void> _pendingOperation = Future<void>.value();

  @override
  Future<void> initialize() async {
    if (_initialized || !_isIOS()) {
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
    return _enqueueOperation(() async {
      if (!_isIOS()) {
        return;
      }

      await initialize();

      final supported = await _liveActivities.areActivitiesSupported();
      if (!supported) {
        return;
      }

      await _reconcileLegacyActivitiesIfNeeded();

      final enabled = await _liveActivities.areActivitiesEnabled();
      if (!enabled) {
        return;
      }

      final payload = <String, dynamic>{
        'lastFeedAtMs': model.lastFeedAt.millisecondsSinceEpoch,
        'feedMethodKey': model.feedMethod.name,
        'feedMethodZh': _feedMethodZh(model.feedMethod),
        'feedMethodEn': _feedMethodEn(model.feedMethod),
        'quickActionUrl': model.quickActionDeepLink,
        if (model.nextReminderAt != null)
          'nextReminderAtMs': model.nextReminderAt!.millisecondsSinceEpoch,
        if (model.feedAmountMl != null) 'feedAmountMl': model.feedAmountMl,
      };

      await _liveActivities.createOrUpdateActivity(
        activityId,
        payload,
        removeWhenAppIsKilled: false,
        iOSEnableRemoteUpdates: false,
        staleIn: const Duration(hours: 8),
      );
    });
  }

  @override
  Future<void> hide() async {
    return _enqueueOperation(() async {
      if (!_isIOS()) {
        return;
      }
      await initialize();
      final supported = await _liveActivities.areActivitiesSupported();
      if (!supported) {
        return;
      }
      await _reconcileLegacyActivitiesIfNeeded();
      await _liveActivities.endActivity(activityId);
    });
  }

  Future<void> _reconcileLegacyActivitiesIfNeeded() async {
    if (_didInitialReconcile) {
      return;
    }

    _didInitialReconcile = true;
    try {
      // Clean up potential legacy/duplicate activities left by older builds.
      await _liveActivities.endAllActivities();
    } catch (_) {}
  }

  Future<void> _enqueueOperation(Future<void> Function() action) {
    final completer = Completer<void>();
    _pendingOperation = _pendingOperation.catchError((_) {}).then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
