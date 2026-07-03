import 'package:flutter/material.dart';

/// Parses a Postgres `time` string ("07:00:00" or "07:00") into a [TimeOfDay].
TimeOfDay timeOfDayFromDb(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Formats a [TimeOfDay] back into the "HH:mm:ss" form Postgres expects.
String timeOfDayToDb(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

/// "7:00 AM" style display, matching the prototype.
String formatTimeOfDay(TimeOfDay t) {
  final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

String formatDateTimeAsTime(DateTime dt) {
  return formatTimeOfDay(TimeOfDay(hour: dt.hour, minute: dt.minute));
}

int timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
