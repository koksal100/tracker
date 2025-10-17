
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:trackerapp/models/task.dart';

class NotificationController {
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
      null, // null uses default icon 'resource://drawable/res_app_icon'
      [
        NotificationChannel(
          channelKey: 'task_alerts',
          channelName: 'Görev Uyarıları',
          channelDescription: 'Planlanmış görevler için bildirim uyarıları',
          playSound: true,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
        )
      ],
      debug: true,
    );
  }

  static Future<void> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleNotification(Task task, DateTime scheduledDate) async {
    if (!task.notificationsEnabled || task.time == null) return;

    final DateTime scheduledDateTime = scheduledDate.copyWith(
      hour: task.time!.hour,
      minute: task.time!.minute,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: task.id.hashCode,
        channelKey: 'task_alerts',
        title: task.name,
        body: task.description.isNotEmpty ? task.description : 'Göreviniz şimdi başlıyor.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDateTime, allowWhileIdle: true),
    );
  }

  static Future<void> cancelNotification(Task task) async {
    await AwesomeNotifications().cancel(task.id.hashCode);
  }
}
