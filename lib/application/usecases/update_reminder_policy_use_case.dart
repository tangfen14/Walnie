import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';

class UpdateReminderPolicyUseCase {
  UpdateReminderPolicyUseCase(this._reminderService);

  final ReminderService _reminderService;

  Future<void> call(ReminderPolicy policy) async {
    policy.validate();
    await _reminderService.upsertPolicy(policy);
    await _reminderService.scheduleNextFromLatestFeed();
  }
}
