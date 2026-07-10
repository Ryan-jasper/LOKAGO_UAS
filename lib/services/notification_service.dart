import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 1001;

  Future<void> init() async {
    tz.initializeTimeZones();

    final TimezoneInfo timezoneInfo =
        await FlutterTimezone.getLocalTimezone();

    final String timeZoneName = timezoneInfo.identifier;

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    await _requestAndroidPermission();
  }

  Future<void> _requestAndroidPermission() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    final notifGranted =
        await androidPlugin.requestNotificationsPermission();

    debugPrint('NotificationService: izin notifikasi granted=$notifGranted');
  }

  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'lokago_daily_reminder_v2',
      'Daily Learning Reminder',
      channelDescription: 'Reminder harian untuk belajar bahasa daerah.',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: 1,
      title: 'LOKAGO',
      body: 'Ayo lanjut belajar bahasa daerah hari ini!',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> scheduleDailyReminder({
    int hour = 19,
    int minute = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lokago_daily_reminder_v2',
      'Daily Learning Reminder',
      channelDescription: 'Reminder harian untuk belajar bahasa daerah.',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id: dailyReminderId,
        title: 'Saatnya belajar di LOKAGO!',
        body: 'Jaga streak kamu dan lanjutkan level hari ini 🔥',
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        'NotificationService: reminder harian terjadwal jam $hour:$minute',
      );
    } catch (e) {
      debugPrint('NotificationService: gagal menjadwalkan reminder -> $e');
      rethrow;
    }
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(
      id: dailyReminderId,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}