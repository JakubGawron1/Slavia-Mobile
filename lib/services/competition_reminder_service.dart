import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'push_notification_service.dart';

/// Lokalne przypomnienie wieczorem przed dniem startu (idea #148).
class CompetitionReminderService {
  CompetitionReminderService._();

  static const _androidChannel = 'slavia_start_reminders';

  static int notificationId(String competitionId) =>
      competitionId.hashCode & 0x3FFFFFFF;

  static Future<void> schedule({
    required String competitionId,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final reminderDay = eventDay.subtract(const Duration(days: 1));
    final at = DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      18,
      0,
    );
    if (!at.isAfter(DateTime.now())) return;

    final plugin = PushNotificationService().plugin;
    final tzDate = tz.TZDateTime.from(at, tz.local);

    final android = AndroidNotificationDetails(
      _androidChannel,
      'Przypomnienia o startach',
      channelDescription: 'Powiadomienia wieczorem przed zawodami',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/launcher_icon',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    await plugin.zonedSchedule(
      id: notificationId(competitionId),
      title: 'Jutro start',
      body: eventTitle,
      scheduledDate: tzDate,
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(String competitionId) async {
    await PushNotificationService().plugin.cancel(
      id: notificationId(competitionId),
    );
  }
}
