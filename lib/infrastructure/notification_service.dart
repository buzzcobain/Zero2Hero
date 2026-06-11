import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  final List<String> _affirmations = [
    "Time to lift! Let's get to it.",
    "This is your reminder to keep getting it!",
    "No excuses today. Your workout awaits!",
    "Zero to Hero: It's time to build that strength.",
    "Time to crush your goals. Ready to lift?",
    "Your future self will thank you for this workout.",
    "Consistency is key. Let's hit the weights!"
  ];

  Future<void> init() async {
    if (_initialized) return;
    
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleWorkoutReminders(Map<String, String> schedule, int offsetMinutes, bool enabled) async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    if (!enabled || schedule.isEmpty) return;

    final random = Random();

    int notificationId = 0;
    
    schedule.forEach((dayString, timeString) {
      final int targetWeekday = int.tryParse(dayString) ?? 1; // 1=Mon, 7=Sun
      final parts = timeString.split(':');
      if (parts.length != 2) return;
      
      final int hour = int.tryParse(parts[0]) ?? 7;
      final int minute = int.tryParse(parts[1]) ?? 0;

      final message = _affirmations[random.nextInt(_affirmations.length)];

      _scheduleWeeklyNotification(
        id: notificationId++,
        weekday: targetWeekday,
        hour: hour,
        minute: minute,
        offsetMinutes: offsetMinutes,
        title: 'Zero2Hero',
        body: message,
      );
    });
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int weekday, // 1 to 7
    required int hour,
    required int minute,
    required int offsetMinutes,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Construct the next occurrence of this day and time
    var targetDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Shift the date to the correct weekday
    while (targetDate.weekday != weekday) {
      targetDate = targetDate.add(const Duration(days: 1));
    }
    
    // Apply offset
    targetDate = targetDate.subtract(Duration(minutes: offsetMinutes));
    
    // If the time has already passed this week, schedule for next week
    if (targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 7));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'workout_reminders',
      'Workout Reminders',
      channelDescription: 'Notifications to remind you of your scheduled workouts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: targetDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
