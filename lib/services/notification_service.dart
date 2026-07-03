import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/regimen_item.dart';

/// Schedules and cancels local notifications for regimen items (by
/// [RegimenItem.fixedTimes]) and appointments (by
/// [Appointment.reminderLeadMinutes]). Every schedule/reschedule call for an
/// entity first cancels its previous notifications, so edits and deletes
/// stay in sync with what's actually queued on-device.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _available = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (_) {
      // Fall back to whatever tz.local defaults to (UTC) if detection fails.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _available = true;
    } catch (_) {
      // The local notification service isn't available on this device/OS
      // (e.g. no notification daemon). Scheduling calls below become no-ops
      // rather than crashing app startup.
    }

    _initialized = true;
  }

  // ---- Regimen items ----------------------------------------------------

  Future<void> scheduleForRegimenItem(RegimenItem item) async {
    await cancelForRegimenItem(item.id!);
    if (!_available || !item.active || item.fixedTimes.isEmpty) return;

    final details = _detailsForReminderStyle(item.reminderStyle);

    for (var i = 0; i < item.fixedTimes.length; i++) {
      final t = item.fixedTimes[i];
      final scheduled = _nextInstanceOfTime(t.hour, t.minute);
      await _plugin.zonedSchedule(
        id: _regimenNotificationId(item.id!, i),
        title: item.name,
        body: item.doseNote == null || item.doseNote!.isEmpty
            ? 'Time to take this.'
            : item.doseNote,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'regimen:${item.id}',
      );
    }
  }

  Future<void> cancelForRegimenItem(String itemId) async {
    if (!_available) return;
    // Fixed_times items support at most a handful of daily doses; 12 is a
    // safe upper bound for cancellation sweep.
    for (var i = 0; i < 12; i++) {
      await _plugin.cancel(id: _regimenNotificationId(itemId, i));
    }
  }

  // ---- Appointments -------------------------------------------------------

  Future<void> scheduleForAppointment(Appointment appt) async {
    await cancelForAppointment(appt.id!);
    if (!_available) return;

    for (var i = 0; i < appt.reminderLeadMinutes.length; i++) {
      final lead = appt.reminderLeadMinutes[i];
      final fireAt = appt.startTime.subtract(Duration(minutes: lead));

      if (appt.recurs && appt.recurrenceDaysOfWeek != null && appt.recurrenceDaysOfWeek!.isNotEmpty) {
        // Schedule one weekly-repeating notification per configured weekday.
        for (var dIdx = 0; dIdx < appt.recurrenceDaysOfWeek!.length; dIdx++) {
          final weekday = appt.recurrenceDaysOfWeek![dIdx];
          final scheduled = _nextInstanceOfWeekdayTime(weekday, fireAt.hour, fireAt.minute);
          await _plugin.zonedSchedule(
            id: _appointmentNotificationId(appt.id!, i * 10 + dIdx),
            title: appt.title,
            body: _appointmentBody(appt, lead),
            scheduledDate: scheduled,
            notificationDetails: _appointmentDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'appointment:${appt.id}',
          );
        }
      } else {
        if (fireAt.isBefore(DateTime.now())) continue;
        final scheduled = tz.TZDateTime.from(fireAt, tz.local);
        await _plugin.zonedSchedule(
          id: _appointmentNotificationId(appt.id!, i),
          title: appt.title,
          body: _appointmentBody(appt, lead),
          scheduledDate: scheduled,
          notificationDetails: _appointmentDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'appointment:${appt.id}',
        );
      }
    }
  }

  Future<void> cancelForAppointment(String apptId) async {
    if (!_available) return;
    // Covers up to 10 lead times, each with up to 10 weekday variants.
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(id: _appointmentNotificationId(apptId, i));
    }
  }

  String _appointmentBody(Appointment appt, int leadMinutes) {
    final where = appt.location == null || appt.location!.isEmpty ? '' : ' at ${appt.location}';
    if (leadMinutes >= 1440) {
      final days = leadMinutes ~/ 1440;
      return '${appt.type.label}$where — in $days day${days == 1 ? '' : 's'}.';
    }
    if (leadMinutes >= 60) {
      final hours = leadMinutes ~/ 60;
      return '${appt.type.label}$where — in $hours hour${hours == 1 ? '' : 's'}.';
    }
    return '${appt.type.label}$where — in $leadMinutes min.';
  }

  NotificationDetails _detailsForReminderStyle(ReminderStyle style) {
    switch (style) {
      case ReminderStyle.gentle:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'regimen_gentle',
            'Gentle reminders',
            channelDescription: 'Soft, dismissible nudges for supplements and practices.',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
          ),
          iOS: DarwinNotificationDetails(presentSound: false),
        );
      case ReminderStyle.standard:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'regimen_standard',
            'Standard reminders',
            channelDescription: 'On-time reminders for meds and herbal remedies.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        );
      case ReminderStyle.insistent:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'regimen_insistent',
            'Insistent reminders',
            channelDescription: 'Repeated, hard-to-miss reminders.',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
        );
    }
  }

  static const NotificationDetails _appointmentDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'appointments',
      'Appointment reminders',
      channelDescription: 'Reminders for medical visits, therapy, and classes.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _regimenNotificationId(String itemId, int timeIndex) {
    final base = itemId.hashCode.abs() % 10000000;
    return base * 100 + timeIndex;
  }

  int _appointmentNotificationId(String apptId, int leadIndex) {
    final base = apptId.hashCode.abs() % 10000000;
    return 1000000000 + base * 100 + leadIndex;
  }
}
