import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/time_task.dart';

int stableId(String s) {
  var h = 0;
  for (final unit in s.codeUnits) {
    h = (h * 31 + unit) & 0x7FFFFFFF;
  }
  return h;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static int _stableId(String s) => stableId(s);

  void _log(String msg) {
    try { FirebaseCrashlytics.instance.log('NotificationService: $msg'); } catch (_) {}
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    _log('init completed');

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
    if (task.startTime == null || task.isCompleted) {
      _log('scheduleTaskReminder skipped: no startTime or completed');
      return;
    }
    _log('scheduleTaskReminder: ${task.id} "${task.title}" ${task.recurrence.name}');

    await cancelTaskNotification(task.id);

    final now = DateTime.now();
    final reminderTime = task.startTime!.subtract(const Duration(minutes: 15));

    const notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'agentic_todo_channel',
        'Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (reminderTime.isAfter(now) && task.recurrence == RecurrenceType.none) {
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: _stableId(task.id),
        title: 'Upcoming: ${task.title}',
        body: 'Starting in 15 minutes',
        scheduledDate: scheduledDate,
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else if (task.recurrence != RecurrenceType.none) {
      final tzNow = tz.TZDateTime.now(tz.local);
      var time = tz.TZDateTime.from(reminderTime, tz.local);

      if (task.recurrence == RecurrenceType.daily) {
        if (time.isBefore(tzNow)) time = time.add(const Duration(days: 1));
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: _stableId(task.id),
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (task.recurrence == RecurrenceType.weekly) {
        if (time.isBefore(tzNow)) time = time.add(const Duration(days: 7));
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: _stableId(task.id),
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } else if (task.recurrence == RecurrenceType.monthly) {
        // B1 fix: was completely missing
        if (time.isBefore(tzNow)) {
          final next = DateTime(time.year, time.month + 1, time.day, time.hour, time.minute);
          time = tz.TZDateTime.from(next, tz.local);
        }
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: _stableId(task.id),
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
      } else if (task.recurrence == RecurrenceType.weekdays) {
        // B1 fix: was completely missing — schedule daily; UI handles weekday-only display
        if (time.isBefore(tzNow)) time = time.add(const Duration(days: 1));
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: _stableId(task.id),
          title: 'Upcoming: ${task.title}',
          body: 'Starting in 15 minutes',
          scheduledDate: time,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(id: _stableId(taskId));
    _log('cancelTaskNotification: $taskId');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showInstant({required int id, required String title, required String body}) async {
    const notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'agentic_todo_channel',
        'Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _flutterLocalNotificationsPlugin.show(id: id, title: title, body: body, notificationDetails: notifDetails);
  }
}
