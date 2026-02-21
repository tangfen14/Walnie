import 'package:baby_tracker/domain/entities/reminder_policy.dart';

abstract class ReminderPolicyRepository {
  Future<ReminderPolicy> getPolicy();

  Future<ReminderPolicy> upsertPolicy(ReminderPolicy policy);
}
