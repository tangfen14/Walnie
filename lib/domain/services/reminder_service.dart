import 'package:baby_tracker/domain/entities/reminder_policy.dart';

abstract class ReminderService {
  Future<void> upsertPolicy(ReminderPolicy policy);

  Future<void> scheduleNextFromLatestFeed();

  Future<DateTime?> nextTriggerTime();

  Future<ReminderPolicy> currentPolicy();
}
