import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/today_summary.dart';

class HomeState {
  const HomeState({
    required this.allTimeline,
    required this.timeline,
    required this.todaySummary,
    required this.intervalHours,
    required this.nextReminderAt,
    this.isTimelineRefreshing = false,
    this.uiNotice,
    this.uiNoticeVersion = 0,
    this.filterType,
  });

  final List<BabyEvent> allTimeline;
  final List<BabyEvent> timeline;
  final TodaySummary todaySummary;
  final int intervalHours;
  final DateTime? nextReminderAt;
  final bool isTimelineRefreshing;
  final String? uiNotice;
  final int uiNoticeVersion;
  final EventType? filterType;

  HomeState copyWith({
    List<BabyEvent>? allTimeline,
    List<BabyEvent>? timeline,
    TodaySummary? todaySummary,
    int? intervalHours,
    DateTime? nextReminderAt,
    bool clearNextReminderAt = false,
    bool? isTimelineRefreshing,
    String? uiNotice,
    bool clearUiNotice = false,
    int? uiNoticeVersion,
    EventType? filterType,
    bool clearFilterType = false,
  }) {
    return HomeState(
      allTimeline: allTimeline ?? this.allTimeline,
      timeline: timeline ?? this.timeline,
      todaySummary: todaySummary ?? this.todaySummary,
      intervalHours: intervalHours ?? this.intervalHours,
      nextReminderAt: clearNextReminderAt
          ? null
          : (nextReminderAt ?? this.nextReminderAt),
      isTimelineRefreshing: isTimelineRefreshing ?? this.isTimelineRefreshing,
      uiNotice: clearUiNotice ? null : (uiNotice ?? this.uiNotice),
      uiNoticeVersion: uiNoticeVersion ?? this.uiNoticeVersion,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
    );
  }
}
