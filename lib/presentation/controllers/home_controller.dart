import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/answer_query_use_case.dart';
import 'package:baby_tracker/application/usecases/create_event_use_case.dart';
import 'package:baby_tracker/application/usecases/get_timeline_use_case.dart';
import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/application/usecases/update_reminder_policy_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/reminder_policy.dart';
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

  Future<void> refreshData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadState);
  }

  Future<void> addEvent(BabyEvent event) async {
    await _createEventUseCase(event);
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
    final timeline = await _getTimelineUseCase(filterType: filterType);
    final todaySummary = await _getTodaySummaryUseCase();
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
}
