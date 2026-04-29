import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    debugPrint('[SYSTEM-REBORN] Initializing NotificationService...');
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('[SYSTEM-REBORN] Could not get local timezone: $e');
    }

    if (kIsWeb) {
      debugPrint('[SYSTEM-REBORN] NotificationService skipped on Web');
      return;
    }
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    debugPrint('[SYSTEM-REBORN] NotificationService initialized');
  }

  Future<void> scheduleReminder(Note note) async {
    final reminder = note.reminder;
    if (kIsWeb || reminder == null || reminder.isBefore(DateTime.now())) {
      return;
    }

    // Use a unique ID for each note's reminder. 
    // Since note.id is a string (Firestore ID), we need a way to convert it to an int.
    final int id = note.id.hashCode;

    String body;
    if (note.isChecklist) {
      body = note.checklist.map((i) => '${i.isChecked ? "☑" : "☐"} ${i.text}').join('\n');
      if (body.isEmpty) body = 'Checklist reminder';
    } else {
      body = note.content.isEmpty ? 'Note reminder' : note.content;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      note.title.isEmpty ? 'Reminder' : note.title,
      body,
      tz.TZDateTime.from(reminder, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Note reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String noteId) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(noteId.hashCode);
  }
}
