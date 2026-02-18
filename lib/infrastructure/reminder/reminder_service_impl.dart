import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderServiceImpl implements ReminderService {
  ReminderServiceImpl({
    required EventRepository eventRepository,
    required SharedPreferences sharedPreferences,
    required LocalNotificationService notificationService,
  }) : _eventRepository = eventRepository,
       _sharedPreferences = sharedPreferences,
       _notificationService = notificationService;

  static const String _intervalHoursKey = 'reminder_interval_hours';
  static const String _nextTriggerIsoKey = 'reminder_next_trigger_iso';

  final EventRepository _eventRepository;
  final SharedPreferences _sharedPreferences;
  final LocalNotificationService _notificationService;

  @override
  Future<ReminderPolicy> currentPolicy() async {
    final interval = _sharedPreferences.getInt(_intervalHoursKey) ?? 3;
    return ReminderPolicy(intervalHours: interval);
  }

  @override
  Future<DateTime?> nextTriggerTime() async {
    final raw = _sharedPreferences.getString(_nextTriggerIsoKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw)?.toLocal();
  }

  @override
  Future<void> upsertPolicy(ReminderPolicy policy) async {
    policy.validate();
    await _sharedPreferences.setInt(_intervalHoursKey, policy.intervalHours);
  }

  @override
  Future<void> scheduleNextFromLatestFeed() async {
    final latestFeed = await _eventRepository.latest(EventType.feed);
    if (latestFeed == null) {
      await _notificationService.cancelFeedReminder();
      await _sharedPreferences.remove(_nextTriggerIsoKey);
      return;
    }

    final policy = await currentPolicy();
    final triggerAt = latestFeed.occurredAt.add(
      Duration(hours: policy.intervalHours),
    );

    final scheduledAt = await _notificationService.scheduleFeedReminder(
      triggerAt,
    );
    await _sharedPreferences.setString(
      _nextTriggerIsoKey,
      scheduledAt.toIso8601String(),
    );
  }
}
