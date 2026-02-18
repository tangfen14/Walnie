class ReminderPolicy {
  const ReminderPolicy({required this.intervalHours});

  final int intervalHours;

  ReminderPolicy copyWith({int? intervalHours}) {
    return ReminderPolicy(intervalHours: intervalHours ?? this.intervalHours);
  }

  void validate() {
    if (intervalHours < 1 || intervalHours > 6) {
      throw const FormatException('提醒间隔必须在 1-6 小时之间');
    }
  }
}
