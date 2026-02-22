import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:baby_tracker/application/services/external_action_bus.dart';

typedef NotificationActionCallback =
    void Function(NotificationResponse response);

class LocalNotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const int feedReminderId = 1001;
  static const String feedReminderCategoryId = 'feed_reminder_category';
  static const String quickVoiceFeedActionId =
      ExternalActionParser.quickVoiceFeedActionId;
  static const String quickVoiceFeedPayload =
      ExternalActionParser.quickVoiceFeedDeepLink;

  Future<void> initialize({
    NotificationActionCallback? onNotificationResponse,
  }) async {
    tzdata.initializeTimeZones();

    final timezoneName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    final settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            feedReminderCategoryId,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                quickVoiceFeedActionId,
                '语音喂奶',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
  }

  Future<bool> hasPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final iosEnabled = (await ios?.checkPermissions())?.isEnabled ?? true;
    final macosEnabled = (await macos?.checkPermissions())?.isEnabled ?? true;
    return iosEnabled && macosEnabled;
  }

  Future<bool> requestPermissions() async {
    if (await hasPermissions()) {
      return true;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final macosGranted =
        await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    if (!(iosGranted && macosGranted)) {
      return false;
    }

    return hasPermissions();
  }

  Future<DateTime> scheduleFeedReminder(DateTime triggerAt) async {
    final details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: feedReminderCategoryId,
      ),
    );

    final trigger = triggerAt.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(minutes: 1))
        : triggerAt;

    await _plugin.zonedSchedule(
      feedReminderId,
      '该喂奶了',
      '根据你设置的间隔，建议现在喂奶。',
      tz.TZDateTime.from(trigger, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: quickVoiceFeedPayload,
    );

    return trigger;
  }

  Future<void> cancelFeedReminder() {
    return _plugin.cancel(feedReminderId);
  }

  Future<bool> hasPendingFeedReminder() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((item) => item.id == feedReminderId);
  }
}
