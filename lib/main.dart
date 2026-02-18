import 'package:baby_tracker/app/app.dart';
import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/infrastructure/config/app_environment.dart';
import 'package:baby_tracker/infrastructure/database/app_database.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:baby_tracker/infrastructure/reminder/reminder_service_impl.dart';
import 'package:baby_tracker/infrastructure/repositories/api_event_repository.dart';
import 'package:baby_tracker/infrastructure/repositories/drift_event_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const appEnvironment = AppEnvironment.fromDartDefine();
  final sharedPreferences = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final httpClient = http.Client();
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final localNotificationService = LocalNotificationService(
    notificationsPlugin,
  );

  // Initialize notifications but don't block app startup on failure/hang
  try {
    await localNotificationService.initialize().timeout(
      const Duration(seconds: 5),
    );
    await localNotificationService.requestPermissions().timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Notification init failed or timed out: $e');
  }

  final bootstrapRepository = appEnvironment.useRemoteBackend
      ? ApiEventRepository(
          baseUrl: appEnvironment.normalizedEventApiBaseUrl,
          httpClient: httpClient,
        )
      : DriftEventRepository(database);

  // Schedule reminder in background — don't block runApp
  final bootstrapReminderService = ReminderServiceImpl(
    eventRepository: bootstrapRepository,
    sharedPreferences: sharedPreferences,
    notificationService: localNotificationService,
  );

  // Fire and forget — errors are non-fatal
  bootstrapReminderService.scheduleNextFromLatestFeed().catchError((e) {
    debugPrint('Bootstrap reminder scheduling failed: $e');
  });

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(appEnvironment),
        httpClientProvider.overrideWithValue(httpClient),
        appDatabaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        localNotificationServiceProvider.overrideWithValue(
          localNotificationService,
        ),
      ],
      child: const BabyTrackerApp(),
    ),
  );
}
