import 'package:baby_tracker/application/usecases/answer_query_use_case.dart';
import 'package:baby_tracker/application/usecases/create_event_use_case.dart';
import 'package:baby_tracker/application/usecases/get_timeline_use_case.dart';
import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/application/usecases/parse_voice_command_use_case.dart';
import 'package:baby_tracker/application/usecases/update_reminder_policy_use_case.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/infrastructure/config/app_environment.dart';
import 'package:baby_tracker/infrastructure/database/app_database.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:baby_tracker/infrastructure/repositories/api_event_repository.dart';
import 'package:baby_tracker/infrastructure/reminder/reminder_service_impl.dart';
import 'package:baby_tracker/infrastructure/repositories/drift_event_repository.dart';
import 'package:baby_tracker/infrastructure/voice/llm_fallback_parser.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:baby_tracker/infrastructure/voice/voice_command_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return const AppEnvironment.fromDartDefine();
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase 需要在 ProviderScope 中 override');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences 需要在 ProviderScope 中 override');
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  throw UnimplementedError(
    'LocalNotificationService 需要在 ProviderScope 中 override',
  );
});

final speechToTextProvider = Provider<SpeechToText>((ref) {
  return SpeechToText();
});

final ruleBasedIntentParserProvider = Provider<RuleBasedIntentParser>((ref) {
  return RuleBasedIntentParser();
});

final llmFallbackParserProvider = Provider<LlmFallbackParser>((ref) {
  return const LlmFallbackParser();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  if (env.useRemoteBackend) {
    return ApiEventRepository(
      baseUrl: env.normalizedEventApiBaseUrl,
      httpClient: ref.watch(httpClientProvider),
    );
  }

  final database = ref.watch(appDatabaseProvider);
  return DriftEventRepository(database);
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderServiceImpl(
    eventRepository: ref.watch(eventRepositoryProvider),
    sharedPreferences: ref.watch(sharedPreferencesProvider),
    notificationService: ref.watch(localNotificationServiceProvider),
  );
});

final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  return VoiceCommandServiceImpl(
    speechToText: ref.watch(speechToTextProvider),
    ruleBasedIntentParser: ref.watch(ruleBasedIntentParserProvider),
    llmFallbackParser: ref.watch(llmFallbackParserProvider),
  );
});

final createEventUseCaseProvider = Provider<CreateEventUseCase>((ref) {
  return CreateEventUseCase(
    eventRepository: ref.watch(eventRepositoryProvider),
    reminderService: ref.watch(reminderServiceProvider),
  );
});

final getTimelineUseCaseProvider = Provider<GetTimelineUseCase>((ref) {
  return GetTimelineUseCase(ref.watch(eventRepositoryProvider));
});

final getTodaySummaryUseCaseProvider = Provider<GetTodaySummaryUseCase>((ref) {
  return GetTodaySummaryUseCase(ref.watch(eventRepositoryProvider));
});

final updateReminderPolicyUseCaseProvider =
    Provider<UpdateReminderPolicyUseCase>((ref) {
      return UpdateReminderPolicyUseCase(ref.watch(reminderServiceProvider));
    });

final parseVoiceCommandUseCaseProvider = Provider<ParseVoiceCommandUseCase>((
  ref,
) {
  return ParseVoiceCommandUseCase(ref.watch(voiceCommandServiceProvider));
});

final answerQueryUseCaseProvider = Provider<AnswerQueryUseCase>((ref) {
  return AnswerQueryUseCase(
    getTodaySummaryUseCase: ref.watch(getTodaySummaryUseCaseProvider),
    reminderService: ref.watch(reminderServiceProvider),
  );
});
