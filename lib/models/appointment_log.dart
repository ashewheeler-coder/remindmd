import 'enums.dart';

class AppointmentLog {
  final String? id;
  final String userId;
  final String appointmentId;
  final DateTime occurredAt;
  final AttendanceStatus status;
  final String? notes;

  const AppointmentLog({
    this.id,
    required this.userId,
    required this.appointmentId,
    required this.occurredAt,
    required this.status,
    this.notes,
  });

  factory AppointmentLog.fromMap(Map<String, dynamic> map) {
    return AppointmentLog(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      appointmentId: map['appointment_id'] as String,
      occurredAt: DateTime.parse(map['occurred_at'] as String).toLocal(),
      status: AttendanceStatusX.fromDb(map['status'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'appointment_id': appointmentId,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'status': status.dbValue,
      'notes': notes,
    };
  }
}
