import 'dart:async';

import 'package:baby_tracker/app/app.dart';
import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/services/external_action_bus.dart';
import 'package:baby_tracker/infrastructure/config/app_environment.dart';
import 'package:baby_tracker/infrastructure/database/app_database.dart';
import 'package:baby_tracker/infrastructure/reminder/live_activity_feed_reminder_surface_service.dart';
import 'package:baby_tracker/infrastructure/reminder/local_notification_service.dart';
import 'package:baby_tracker/infrastructure/reminder/reminder_service_impl.dart';
import 'package:baby_tracker/infrastructure/repositories/api_event_repository.dart';
import 'package:baby_tracker/infrastructure/repositories/api_reminder_policy_repository.dart';
import 'package:baby_tracker/infrastructure/repositories/drift_event_repository.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:live_activities/live_activities.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');

  const appEnvironment = AppEnvironment.fromDartDefine();
  debugPrint(
    'Walnie startup: useRemoteBackend=${appEnvironment.useRemoteBackend}, '
    'EVENT_API_BASE_URL=${appEnvironment.normalizedEventApiBaseUrl}',
  );
  final sharedPreferences = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final httpClient = http.Client();
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final externalActionBus = ExternalActionBus();
  final liveActivities = LiveActivities();
  final reminderSurfaceService = LiveActivityFeedReminderSurfaceService(
    liveActivities: liveActivities,
    appGroupId: 'group.com.wang.walnie.shared',
  );
  final localNotificationService = LocalNotificationService(
    notificationsPlugin,
  );

  // Initialize notifications but don't block app startup on failure/hang
  try {
    await localNotificationService
        .initialize(
          onNotificationResponse: (response) {
            final parsed = ExternalActionParser.fromNotificationAction(
              actionId: response.actionId,
              payload: response.payload,
            );
            if (parsed != null) {
              externalActionBus.dispatch(parsed);
              return;
            }

            final payloadUri = Uri.tryParse(response.payload ?? '');
            if (payloadUri != null) {
              externalActionBus.dispatchUri(payloadUri);
            }
          },
        )
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Notification init failed or timed out: $e');
  }

  try {
    await reminderSurfaceService.initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Reminder surface init failed or timed out: $e');
  }

  final appLinks = AppLinks();
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      externalActionBus.dispatchUri(initialLink);
    }
  } catch (e) {
    debugPrint('Read initial app link failed: $e');
  }
  appLinks.uriLinkStream.listen(
    externalActionBus.dispatchUri,
    onError: (Object error) {
      debugPrint('App link stream error: $error');
    },
  );

  liveActivities.urlSchemeStream().listen(
    (schemeData) {
      final raw = schemeData.url;
      if (raw == null || raw.isEmpty) {
        return;
      }
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        externalActionBus.dispatchUri(uri);
      }
    },
    onError: (Object error) {
      debugPrint('Live activity url stream error: $error');
    },
  );

  final bootstrapRepository = appEnvironment.useRemoteBackend
      ? ApiEventRepository(
          baseUrl: appEnvironment.normalizedEventApiBaseUrl,
          httpClient: httpClient,
        )
      : DriftEventRepository(database);
  final bootstrapReminderPolicyRepository = appEnvironment.useRemoteBackend
      ? ApiReminderPolicyRepository(
          baseUrl: appEnvironment.normalizedEventApiBaseUrl,
          httpClient: httpClient,
        )
      : null;

  // Schedule reminder in background — don't block runApp
  final bootstrapReminderService = ReminderServiceImpl(
    eventRepository: bootstrapRepository,
    sharedPreferences: sharedPreferences,
    notificationService: localNotificationService,
    reminderSurfaceService: reminderSurfaceService,
    reminderPolicyRepository: bootstrapReminderPolicyRepository,
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
        externalActionBusProvider.overrideWithValue(externalActionBus),
        liveActivitiesProvider.overrideWithValue(liveActivities),
        feedReminderSurfaceServiceProvider.overrideWithValue(
          reminderSurfaceService,
        ),
      ],
      child: const BabyTrackerApp(),
    ),
  );

  unawaited(
    _requestNotificationPermissionsAndReschedule(
      localNotificationService: localNotificationService,
      reminderService: bootstrapReminderService,
    ),
  );
}

Future<void> _requestNotificationPermissionsAndReschedule({
  required LocalNotificationService localNotificationService,
  required ReminderServiceImpl reminderService,
}) async {
  try {
    final granted = await localNotificationService.requestPermissions();
    if (!granted) {
      debugPrint('Notification permissions not granted.');
      return;
    }

    await reminderService.scheduleNextFromLatestFeed();
  } catch (e) {
    debugPrint('Notification permission request failed: $e');
  }
}
