import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderNotificationId = 1001;

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      if (!kIsWeb) {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      }
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelDailyReminder();

    if (kIsWeb) {
      debugPrint('Daily reminders on Web are simulated.');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_expense_reminder_channel',
      'Daily Expense Reminders',
      channelDescription: 'Daily reminder to log your expenses for the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: _reminderNotificationId,
        title: 'Expense Tracker',
        body: 'Did you log today\'s expenses? Tap to add them now.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Scheduled daily reminder for $hour:$minute at $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule zoned notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(id: _reminderNotificationId);
  }
}
