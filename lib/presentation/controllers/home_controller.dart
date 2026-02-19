import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/answer_query_use_case.dart';
import 'package:baby_tracker/application/usecases/create_event_use_case.dart';
import 'package:baby_tracker/application/usecases/delete_event_use_case.dart';
import 'package:baby_tracker/application/usecases/get_timeline_use_case.dart';
import 'package:baby_tracker/application/usecases/update_reminder_policy_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/entities/today_summary.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_state.dart';

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends AsyncNotifier<HomeState> {
  late final CreateEventUseCase _createEventUseCase = ref.read(
    createEventUseCaseProvider,
  );
  late final DeleteEventUseCase _deleteEventUseCase = ref.read(
    deleteEventUseCaseProvider,
  );
  late final GetTimelineUseCase _getTimelineUseCase = ref.read(
    getTimelineUseCaseProvider,
  );
  late final UpdateReminderPolicyUseCase _updateReminderPolicyUseCase = ref
      .read(updateReminderPolicyUseCaseProvider);
  late final AnswerQueryUseCase _answerQueryUseCase = ref.read(
    answerQueryUseCaseProvider,
  );

  EventType? filterType;

  @override
  Future<HomeState> build() => _loadState();

  Future<void> refreshData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadState);
  }

  Future<void> addEvent(BabyEvent event) async {
    await _createEventUseCase(event);
    await refreshData();
  }

  Future<void> deleteEvent(BabyEvent event) async {
    await _deleteEventUseCase(event);
    await refreshData();
  }

  Future<void> updateReminderInterval(int intervalHours) async {
    await _updateReminderPolicyUseCase(
      ReminderPolicy(intervalHours: intervalHours),
    );
    await refreshData();
  }

  Future<String> answerQuery(VoiceIntent intent) {
    return _answerQueryUseCase(intent);
  }

  void setFilter(EventType? type) {
    filterType = type;
    refreshData();
  }

  Future<HomeState> _loadState() async {
    const timelineLookbackDays = 7;
    const summaryLookbackDays = 36500; // 近 100 年，作为“全部历史”近似范围

    final allTimeline = await _getTimelineUseCase(
      lookbackDays: timelineLookbackDays,
    );
    final allSummaryEvents = await _getTimelineUseCase(
      lookbackDays: summaryLookbackDays,
    );
    final timeline = filterType == null
        ? allTimeline
        : allTimeline
              .where((event) => event.type == filterType)
              .toList(growable: false);
    final todaySummary = _summaryFromEvents(allSummaryEvents);
    final reminderService = ref.read(reminderServiceProvider);
    final reminderPolicy = await reminderService.currentPolicy();
    final nextTrigger = await reminderService.nextTriggerTime();
    return HomeState(
      timeline: timeline,
      todaySummary: todaySummary,
      intervalHours: reminderPolicy.intervalHours,
      nextReminderAt: nextTrigger,
      filterType: filterType,
    );
  }

  TodaySummary _summaryFromEvents(List<BabyEvent> events) {
    var feedCount = 0;
    var poopCount = 0;
    var peeCount = 0;
    var diaperCount = 0;
    var pumpCount = 0;
    DateTime? latestFeed;

    for (final event in events) {
      switch (event.type) {
        case EventType.feed:
          feedCount += 1;
          if (latestFeed == null || event.occurredAt.isAfter(latestFeed)) {
            latestFeed = event.occurredAt;
          }
          break;
        case EventType.poop:
          poopCount += 1;
          break;
        case EventType.pee:
          peeCount += 1;
          break;
        case EventType.diaper:
          diaperCount += 1;
          break;
        case EventType.pump:
          pumpCount += 1;
          break;
      }
    }

    return TodaySummary(
      feedCount: feedCount,
      poopCount: poopCount,
      peeCount: peeCount,
      diaperCount: diaperCount,
      pumpCount: pumpCount,
      latestFeedAt: latestFeed,
    );
  }
}
