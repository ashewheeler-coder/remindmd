/// Mirrors the Postgres enums defined in supabase/schema.sql.
enum Modality { pharma, herbal, supplement, practice }

extension ModalityX on Modality {
  String get dbValue => name;

  static Modality fromDb(String value) =>
      Modality.values.firstWhere((m) => m.dbValue == value);

  String get label {
    switch (this) {
      case Modality.pharma:
        return 'Pharmaceutical';
      case Modality.herbal:
        return 'Herbal';
      case Modality.supplement:
        return 'Supplement';
      case Modality.practice:
        return 'Practice';
    }
  }
}

enum ApptType { medical, therapy, classType, other }

extension ApptTypeX on ApptType {
  String get dbValue => this == ApptType.classType ? 'class' : name;

  static ApptType fromDb(String value) {
    if (value == 'class') return ApptType.classType;
    return ApptType.values.firstWhere((t) => t.name == value);
  }

  String get label {
    switch (this) {
      case ApptType.medical:
        return 'Medical';
      case ApptType.therapy:
        return 'Therapy';
      case ApptType.classType:
        return 'Class';
      case ApptType.other:
        return 'Other';
    }
  }
}

enum ReminderStyle { gentle, standard, insistent }

extension ReminderStyleX on ReminderStyle {
  String get dbValue => name;

  static ReminderStyle fromDb(String value) =>
      ReminderStyle.values.firstWhere((r) => r.dbValue == value);
}

enum ScheduleKind { fixedTimes, intervalDays, daysOfWeek, asNeeded }

extension ScheduleKindX on ScheduleKind {
  String get dbValue {
    switch (this) {
      case ScheduleKind.fixedTimes:
        return 'fixed_times';
      case ScheduleKind.intervalDays:
        return 'interval_days';
      case ScheduleKind.daysOfWeek:
        return 'days_of_week';
      case ScheduleKind.asNeeded:
        return 'as_needed';
    }
  }

  static ScheduleKind fromDb(String value) =>
      ScheduleKind.values.firstWhere((s) => s.dbValue == value);
}

enum DoseStatus { taken, skipped, snoozed }

extension DoseStatusX on DoseStatus {
  String get dbValue => name;

  static DoseStatus fromDb(String value) =>
      DoseStatus.values.firstWhere((s) => s.dbValue == value);
}

enum AttendanceStatus { attended, missed, rescheduled }

extension AttendanceStatusX on AttendanceStatus {
  String get dbValue => name;

  static AttendanceStatus fromDb(String value) =>
      AttendanceStatus.values.firstWhere((s) => s.dbValue == value);
}
