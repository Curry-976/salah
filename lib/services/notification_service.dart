import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_model.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> scheduleAllPrayers(List<PrayerTime> prayers) async {
    if (kIsWeb) return;
    await _plugin.cancelAll();

    for (final prayer in prayers) {
      if (!prayer.name.isObligatory) continue;
      if (prayer.time.isBefore(DateTime.now())) continue;

      await _schedulePrayer(prayer);
    }
  }

  Future<void> _schedulePrayer(PrayerTime prayer) async {
    final tzTime = tz.TZDateTime.from(prayer.time, tz.local);

    await _plugin.zonedSchedule(
      prayer.name.index,
      'وقت الصلاة - ${prayer.name.arabicName}',
      'حان الآن وقت ${prayer.name.displayName}',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Horaires de prière',
          channelDescription: 'Notifications pour les temps de prière',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('adhan'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'adhan.aiff',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
