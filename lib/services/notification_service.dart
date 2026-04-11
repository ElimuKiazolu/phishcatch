import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const List<String> _tips = [
    'Always check the domain - not just the start of the URL.',
    'HTTPS does not mean safe. It just means encrypted.',
    'Hover over links before clicking to see the real destination.',
    'Shortened URLs hide where they lead - always expand them first.',
    'Urgent messages demanding immediate action are almost always scams.',
    'Your bank will never ask for your password via SMS or email.',
    'Check for subtle typos - paypa1.com not paypal.com.',
    'QR codes can point to phishing sites - scan with PhishCatch first.',
    'Too many subdomains in a URL is a red flag.',
    'When in doubt, go directly to the website - do not click the link.',
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Keep default timezone data when local zone is unavailable.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    await requestPermission();
    await scheduleDailyTip();
  }

  Future<void> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {
      // Permission errors must not crash app startup.
    }
  }

  Future<void> scheduleDailyTip() async {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final tip = _tips[dayOfYear % _tips.length];

    final scheduledDate = _nextTenAm();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'phishcatch_tips',
        'Daily Security Tips',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      1,
      'PhishCatch tip',
      tip,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextTenAm() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

