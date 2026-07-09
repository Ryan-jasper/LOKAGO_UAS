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

    // Ini satu-satunya izin yang benar-benar kita butuhkan. Izin exact
    // alarm SENGAJA tidak diminta di sini — untuk reminder harian, telat
    // beberapa menit tidak masalah, dan izin itu tidak berupa dialog biasa
    // (malah membuka halaman Settings sistem serta tidak bisa dipastikan
    // statusnya lewat return value), jadi lebih aman dihindari sama sekali.
    final notifGranted =
        await androidPlugin.requestNotificationsPermission();

    debugPrint('NotificationService: izin notifikasi granted=$notifGranted');
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'lokago_daily_reminder',
      'Daily Learning Reminder',
      channelDescription: 'Reminder harian untuk belajar bahasa daerah.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
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
    const androidDetails = AndroidNotificationDetails(
      'lokago_daily_reminder',
      'Daily Learning Reminder',
      channelDescription: 'Reminder harian untuk belajar bahasa daerah.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id: dailyReminderId,
        title: 'Saatnya belajar di LOKAGO!',
        body: 'Jaga streak kamu dan lanjutkan level hari ini 🔥',
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: notificationDetails,
        // inexactAllowWhileIdle TIDAK butuh izin SCHEDULE_EXACT_ALARM,
        // dan cukup akurat untuk reminder harian (bisa meleset beberapa
        // menit, bukan masalah untuk kasus ini).
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