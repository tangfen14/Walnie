import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/today_summary.dart';

class HomeState {
  const HomeState({
    required this.timeline,
    required this.todaySummary,
    required this.intervalHours,
    required this.nextReminderAt,
    this.filterType,
  });

  final List<BabyEvent> timeline;
  final TodaySummary todaySummary;
  final int intervalHours;
  final DateTime? nextReminderAt;
  final EventType? filterType;

  HomeState copyWith({
    List<BabyEvent>? timeline,
    TodaySummary? todaySummary,
    int? intervalHours,
    DateTime? nextReminderAt,
    bool clearNextReminderAt = false,
    EventType? filterType,
    bool clearFilterType = false,
  }) {
    return HomeState(
      timeline: timeline ?? this.timeline,
      todaySummary: todaySummary ?? this.todaySummary,
      intervalHours: intervalHours ?? this.intervalHours,
      nextReminderAt: clearNextReminderAt
          ? null
          : (nextReminderAt ?? this.nextReminderAt),
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
    );
  }
}
