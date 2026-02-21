import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/answer_query_use_case.dart';
import 'package:baby_tracker/application/usecases/create_event_use_case.dart';
import 'package:baby_tracker/application/usecases/delete_event_use_case.dart';
import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/application/usecases/get_timeline_use_case.dart';
import 'package:baby_tracker/application/usecases/update_reminder_policy_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:flutter/foundation.dart';
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
  late final GetTodaySummaryUseCase _getTodaySummaryUseCase = ref.read(
    getTodaySummaryUseCaseProvider,
  );
  late final UpdateReminderPolicyUseCase _updateReminderPolicyUseCase = ref
      .read(updateReminderPolicyUseCaseProvider);
  late final AnswerQueryUseCase _answerQueryUseCase = ref.read(
    answerQueryUseCaseProvider,
  );

  EventType? filterType;

  @override
  Future<HomeState> build() => _loadState();

  Future<void> refreshData({String? refreshFailureNotice}) async {
    final previous = state.value;
    if (previous == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_loadState);
      return;
    }

    state = AsyncData(
      previous.copyWith(isTimelineRefreshing: true, clearUiNotice: true),
    );

    try {
      final next = await _loadState();
      state = AsyncData(
        next.copyWith(uiNoticeVersion: previous.uiNoticeVersion),
      );
    } catch (_) {
      state = AsyncData(
        previous.copyWith(
          isTimelineRefreshing: false,
          uiNotice: refreshFailureNotice ?? '刷新失败，请稍后重试',
          uiNoticeVersion: previous.uiNoticeVersion + 1,
        ),
      );
    }
  }

  Future<void> addEvent(BabyEvent event) async {
    await _createEventUseCase(event);
    await refreshData(refreshFailureNotice: '保存成功，刷新失败');
  }

  Future<void> deleteEvent(BabyEvent event) async {
    await _deleteEventUseCase(event);
    await refreshData(refreshFailureNotice: '删除成功，刷新失败');
  }

  Future<void> updateReminderInterval(int intervalHours) async {
    await _updateReminderPolicyUseCase(
      ReminderPolicy(intervalHours: intervalHours),
    );
    await refreshData(refreshFailureNotice: '设置成功，刷新失败');
  }

  Future<String> answerQuery(VoiceIntent intent) {
    return _answerQueryUseCase(intent);
  }

  void setFilter(EventType? type) {
    filterType = type;
    final previous = state.value;
    if (previous == null) {
      return;
    }

    final timeline = _applyFilter(previous.allTimeline, filterType);
    state = AsyncData(
      previous.copyWith(timeline: timeline, filterType: filterType),
    );
  }

  Future<HomeState> _loadState() async {
    const timelineLookbackDays = 7;

    final allTimeline = await _getTimelineUseCase(
      lookbackDays: timelineLookbackDays,
    );
    final timeline = _applyFilter(allTimeline, filterType);
    final todaySummary = await _getTodaySummaryUseCase();
    final reminderService = ref.read(reminderServiceProvider);
    try {
      await reminderService.scheduleNextFromLatestFeed();
    } catch (error, stackTrace) {
      debugPrint('Failed to recalculate next feed reminder: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    final reminderPolicy = await reminderService.currentPolicy();
    final nextTrigger = await reminderService.nextTriggerTime();
    return HomeState(
      allTimeline: allTimeline,
      timeline: timeline,
      todaySummary: todaySummary,
      intervalHours: reminderPolicy.intervalHours,
      nextReminderAt: nextTrigger,
      isTimelineRefreshing: false,
      uiNotice: null,
      uiNoticeVersion: 0,
      filterType: filterType,
    );
  }

  List<BabyEvent> _applyFilter(List<BabyEvent> source, EventType? type) {
    if (type == null) {
      return source;
    }

    return source
        .where((event) {
          if (type == EventType.diaper) {
            return event.type == EventType.diaper ||
                event.type == EventType.poop ||
                event.type == EventType.pee;
          }
          return event.type == type;
        })
        .toList(growable: false);
  }
}
