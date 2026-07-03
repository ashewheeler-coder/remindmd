import 'package:flutter/material.dart';

import 'appointment.dart';
import 'regimen_item.dart';

/// A single row in the Today day-rail: either a scheduled dose instance or
/// an appointment happening today, merged and sorted by time.
class TodayEntry {
  final bool isDose;
  final TimeOfDay time;

  final RegimenItem? regimenItem;
  final bool doseTaken;

  final Appointment? appointment;

  const TodayEntry.dose({
    required RegimenItem item,
    required this.time,
    required this.doseTaken,
  })  : isDose = true,
        regimenItem = item,
        appointment = null;

  const TodayEntry.appointment({
    required Appointment appt,
    required this.time,
  })  : isDose = false,
        appointment = appt,
        doseTaken = false,
        regimenItem = null;

  int get minutesOfDay => time.hour * 60 + time.minute;
}
