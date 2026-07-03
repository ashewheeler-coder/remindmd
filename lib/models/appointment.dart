import 'enums.dart';

class Appointment {
  final String? id;
  final String userId;

  final String title;
  final ApptType type;
  final String? location;
  final String? notes;

  final DateTime startTime;
  final DateTime? endTime;

  final bool recurs;
  final List<int>? recurrenceDaysOfWeek;
  final int? recurrenceIntervalDays;

  final List<int> reminderLeadMinutes;

  const Appointment({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    this.location,
    this.notes,
    required this.startTime,
    this.endTime,
    this.recurs = false,
    this.recurrenceDaysOfWeek,
    this.recurrenceIntervalDays,
    this.reminderLeadMinutes = const [60],
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      type: ApptTypeX.fromDb(map['type'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String).toLocal() : null,
      recurs: map['recurs'] as bool? ?? false,
      recurrenceDaysOfWeek: (map['recurrence_days_of_week'] as List?)?.map((e) => e as int).toList(),
      recurrenceIntervalDays: map['recurrence_interval_days'] as int?,
      reminderLeadMinutes: ((map['reminder_lead_minutes'] as List?) ?? [60])
          .map((e) => e as int)
          .toList(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'type': type.dbValue,
      'location': location,
      'notes': notes,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'recurs': recurs,
      'recurrence_days_of_week': recurrenceDaysOfWeek,
      'recurrence_interval_days': recurrenceIntervalDays,
      'reminder_lead_minutes': reminderLeadMinutes,
    };
  }

  Appointment copyWith({
    String? id,
    String? title,
    ApptType? type,
    String? location,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    bool? recurs,
    List<int>? recurrenceDaysOfWeek,
    int? recurrenceIntervalDays,
    List<int>? reminderLeadMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurs: recurs ?? this.recurs,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
      recurrenceIntervalDays: recurrenceIntervalDays ?? this.recurrenceIntervalDays,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    );
  }
}
