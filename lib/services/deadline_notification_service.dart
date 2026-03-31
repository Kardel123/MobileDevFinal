import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/academic_task.dart';

/// Schedules local reminders for pending tasks (Android / iOS only).
class DeadlineNotificationService {
  DeadlineNotificationService._();
  static final DeadlineNotificationService instance =
      DeadlineNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  /// Cancel all scheduled task reminders and reschedule from [tasks].
  Future<void> syncFromTasks(List<AcademicTask> tasks) async {
    if (!_supported || !_initialized) return;

    await _plugin.cancelAll();

    final now = DateTime.now();
    var notificationId = 9000;

    for (final t in tasks) {
      if (t.status == AcademicTaskStatus.done) continue;
      final dueDay = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      if (dueDay.isBefore(DateTime(now.year, now.month, now.day))) continue;

      final scheduledLocal = DateTime(
        dueDay.year,
        dueDay.month,
        dueDay.day,
        9,
        0,
      );
      if (!scheduledLocal.isAfter(now)) continue;

      final zoned = tz.TZDateTime.from(scheduledLocal, tz.local);
      try {
        await _plugin.zonedSchedule(
          notificationId++,
          'Due today: ${t.title}',
          t.subject,
          zoned,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_deadlines',
              'Task deadlines',
              channelDescription: 'Reminders when assignments are due',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Ignore scheduling failures (e.g. permission denied).
      }
    }
  }
}
