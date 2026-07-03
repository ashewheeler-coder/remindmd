import 'package:flutter/material.dart';

import '../utils/time_utils.dart';
import 'enums.dart';

class RegimenItem {
  final String? id;
  final String userId;

  final String name;
  final Modality modality;
  final String? doseNote;

  final ScheduleKind scheduleKind;
  final List<TimeOfDay> fixedTimes;
  final int? intervalDays;
  final List<int>? daysOfWeek;

  final ReminderStyle reminderStyle;
  final bool active;

  final double? supplyOnHand;
  final double? supplyPerDose;
  final String? supplyUnit;
  final double? supplyReorderThreshold;

  const RegimenItem({
    this.id,
    required this.userId,
    required this.name,
    required this.modality,
    this.doseNote,
    this.scheduleKind = ScheduleKind.fixedTimes,
    this.fixedTimes = const [],
    this.intervalDays,
    this.daysOfWeek,
    this.reminderStyle = ReminderStyle.standard,
    this.active = true,
    this.supplyOnHand,
    this.supplyPerDose,
    this.supplyUnit,
    this.supplyReorderThreshold,
  });

  bool get tracksSupply => supplyOnHand != null && supplyPerDose != null;

  /// Doses per day, used for supply countdown math. Only meaningful for
  /// fixed_times schedules (the only kind the current UI creates).
  double get dosesPerDay {
    switch (scheduleKind) {
      case ScheduleKind.fixedTimes:
        return fixedTimes.isEmpty ? 1 : fixedTimes.length.toDouble();
      case ScheduleKind.daysOfWeek:
        final days = daysOfWeek?.length ?? 7;
        return days / 7;
      case ScheduleKind.intervalDays:
        final interval = intervalDays ?? 1;
        return interval <= 0 ? 1 : 1 / interval;
      case ScheduleKind.asNeeded:
        return 0;
    }
  }

  double? get remainingDays {
    if (!tracksSupply) return null;
    final perDose = supplyPerDose!;
    final perDay = dosesPerDay * perDose;
    if (perDay <= 0) return null;
    return supplyOnHand! / perDay;
  }

  bool get isLowSupply {
    final remaining = remainingDays;
    final threshold = supplyReorderThreshold;
    if (remaining == null || threshold == null) return false;
    return supplyOnHand! <= threshold;
  }

  factory RegimenItem.fromMap(Map<String, dynamic> map) {
    return RegimenItem(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      modality: ModalityX.fromDb(map['modality'] as String),
      doseNote: map['dose_note'] as String?,
      scheduleKind: ScheduleKindX.fromDb(map['schedule_kind'] as String? ?? 'fixed_times'),
      fixedTimes: ((map['fixed_times'] as List?) ?? [])
          .map((t) => timeOfDayFromDb(t as String))
          .toList(),
      intervalDays: map['interval_days'] as int?,
      daysOfWeek: (map['days_of_week'] as List?)?.map((e) => e as int).toList(),
      reminderStyle: ReminderStyleX.fromDb(map['reminder_style'] as String? ?? 'standard'),
      active: map['active'] as bool? ?? true,
      supplyOnHand: (map['supply_on_hand'] as num?)?.toDouble(),
      supplyPerDose: (map['supply_per_dose'] as num?)?.toDouble(),
      supplyUnit: map['supply_unit'] as String?,
      supplyReorderThreshold: (map['supply_reorder_threshold'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'modality': modality.dbValue,
      'dose_note': doseNote,
      'schedule_kind': scheduleKind.dbValue,
      'fixed_times': fixedTimes.map(timeOfDayToDb).toList(),
      'interval_days': intervalDays,
      'days_of_week': daysOfWeek,
      'reminder_style': reminderStyle.dbValue,
      'active': active,
      'supply_on_hand': supplyOnHand,
      'supply_per_dose': supplyPerDose,
      'supply_unit': supplyUnit,
      'supply_reorder_threshold': supplyReorderThreshold,
    };
  }

  RegimenItem copyWith({
    String? id,
    String? name,
    Modality? modality,
    String? doseNote,
    ScheduleKind? scheduleKind,
    List<TimeOfDay>? fixedTimes,
    int? intervalDays,
    List<int>? daysOfWeek,
    ReminderStyle? reminderStyle,
    bool? active,
    double? supplyOnHand,
    double? supplyPerDose,
    String? supplyUnit,
    double? supplyReorderThreshold,
  }) {
    return RegimenItem(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      modality: modality ?? this.modality,
      doseNote: doseNote ?? this.doseNote,
      scheduleKind: scheduleKind ?? this.scheduleKind,
      fixedTimes: fixedTimes ?? this.fixedTimes,
      intervalDays: intervalDays ?? this.intervalDays,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      active: active ?? this.active,
      supplyOnHand: supplyOnHand ?? this.supplyOnHand,
      supplyPerDose: supplyPerDose ?? this.supplyPerDose,
      supplyUnit: supplyUnit ?? this.supplyUnit,
      supplyReorderThreshold: supplyReorderThreshold ?? this.supplyReorderThreshold,
    );
  }
}
