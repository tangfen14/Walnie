import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/repositories/reminder_policy_repository.dart';
import 'package:baby_tracker/domain/services/feed_reminder_surface_service.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderServiceImpl implements ReminderService {
  ReminderServiceImpl({
    required EventRepository eventRepository,
    required SharedPreferences sharedPreferences,
    required LocalNotificationService notificationService,
    required FeedReminderSurfaceService reminderSurfaceService,
    ReminderPolicyRepository? reminderPolicyRepository,
  }) : _eventRepository = eventRepository,
       _sharedPreferences = sharedPreferences,
       _notificationService = notificationService,
       _reminderSurfaceService = reminderSurfaceService,
       _reminderPolicyRepository = reminderPolicyRepository;

  static const String _intervalHoursKey = 'reminder_interval_hours';
  static const String _nextTriggerIsoKey = 'reminder_next_trigger_iso';

  final EventRepository _eventRepository;
  final SharedPreferences _sharedPreferences;
  final LocalNotificationService _notificationService;
  final FeedReminderSurfaceService _reminderSurfaceService;
  final ReminderPolicyRepository? _reminderPolicyRepository;

  @override
  Future<ReminderPolicy> currentPolicy() async {
    if (_reminderPolicyRepository != null) {
      try {
        final remotePolicy = await _reminderPolicyRepository.getPolicy();
        await _sharedPreferences.setInt(
          _intervalHoursKey,
          remotePolicy.intervalHours,
        );
        return remotePolicy;
      } catch (error, stackTrace) {
        debugPrint('Failed to fetch remote reminder policy: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final interval = _sharedPreferences.getInt(_intervalHoursKey) ?? 3;
    return ReminderPolicy(intervalHours: interval);
  }

  @override
  Future<DateTime?> nextTriggerTime() async {
    final raw = _sharedPreferences.getString(_nextTriggerIsoKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return _parseIsoWallClock(raw);
  }

  @override
  Future<void> upsertPolicy(ReminderPolicy policy) async {
    policy.validate();
    await _sharedPreferences.setInt(_intervalHoursKey, policy.intervalHours);

    if (_reminderPolicyRepository == null) {
      return;
    }

    try {
      final syncedPolicy = await _reminderPolicyRepository.upsertPolicy(policy);
      await _sharedPreferences.setInt(
        _intervalHoursKey,
        syncedPolicy.intervalHours,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to sync remote reminder policy: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> scheduleNextFromLatestFeed() async {
    final latestFeed = await _eventRepository.latest(EventType.feed);
    if (latestFeed == null) {
      await _notificationService.cancelFeedReminder();
      await _safeHideReminderSurface();
      await _sharedPreferences.remove(_nextTriggerIsoKey);
      return;
    }

    final policy = await currentPolicy();
    final latestFeedWallClock = _toWallClock(latestFeed.occurredAt);
    final triggerAt = latestFeedWallClock.add(
      Duration(hours: policy.intervalHours),
    );

    final scheduledAt = await _notificationService.scheduleFeedReminder(
      triggerAt,
    );
    await _sharedPreferences.setString(
      _nextTriggerIsoKey,
      scheduledAt.toIso8601String(),
    );

    await _safeShowReminderSurface(
      FeedReminderSurfaceModel(
        lastFeedAt: latestFeedWallClock,
        nextReminderAt: scheduledAt,
        feedMethod: latestFeed.feedMethod ?? FeedMethod.bottleBreastmilk,
        quickActionDeepLink: LocalNotificationService.quickVoiceFeedPayload,
      ),
    );
  }

  DateTime _toWallClock(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  DateTime? _parseIsoWallClock(String raw) {
    final normalized = raw.trim();
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?',
    ).firstMatch(normalized);

    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = match.group(6) == null ? 0 : int.parse(match.group(6)!);
      final fraction = match.group(7);
      final microTotal = fraction == null
          ? 0
          : int.parse(fraction.padRight(6, '0').substring(0, 6));

      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        microTotal ~/ 1000,
        microTotal % 1000,
      );
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return null;
    }
    return _toWallClock(parsed);
  }

  Future<void> _safeShowReminderSurface(FeedReminderSurfaceModel model) async {
    try {
      await _reminderSurfaceService.showOrUpdate(model);
    } catch (error, stackTrace) {
      debugPrint('Failed to show/update reminder surface: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _safeHideReminderSurface() async {
    try {
      await _reminderSurfaceService.hide();
    } catch (error, stackTrace) {
      debugPrint('Failed to hide reminder surface: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
