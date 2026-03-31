import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/time_task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleTaskReminder(TimeTask task) async {
    if (task.startTime == null || task.isCompleted) return;

    // Remove existing notifications for this task just in case
    await cancelNotification(task.id.hashCode);

    final now = DateTime.now();
    final reminderTime = task.startTime!.subtract(const Duration(minutes: 15));

    // Only schedule if the reminder time is in the future
    if (reminderTime.isAfter(now) && task.recurrence == RecurrenceType.none) {
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: 'Upcoming: ${task.title}',
        body: 'Starting in 15 minutes',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'agentic_todo_channel',
            'Reminders',
            channelDescription: 'Notifications for upcoming tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } 
    // For recurring tasks, we can schedule weekly or daily depending on the recurrence
    else if (task.recurrence != RecurrenceType.none) {
      if (task.recurrence == RecurrenceType.daily) {
        final time = tz.TZDateTime.from(reminderTime, tz.local);
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: task.id.hashCode,
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time.isBefore(tz.TZDateTime.now(tz.local)) ? time.add(const Duration(days: 1)) : time,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'agentic_todo_channel',
              'Reminders',
              channelDescription: 'Notifications for upcoming tasks',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (task.recurrence == RecurrenceType.weekly) {
        final time = tz.TZDateTime.from(reminderTime, tz.local);
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: task.id.hashCode,
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time.isBefore(tz.TZDateTime.now(tz.local)) ? time.add(const Duration(days: 7)) : time,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'agentic_todo_channel',
              'Reminders',
              channelDescription: 'Notifications for upcoming tasks',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

