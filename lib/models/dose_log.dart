import 'enums.dart';

class DoseLog {
  final String? id;
  final String userId;
  final String regimenItemId;
  final DateTime scheduledFor;
  final DateTime? loggedAt;
  final DoseStatus status;

  const DoseLog({
    this.id,
    required this.userId,
    required this.regimenItemId,
    required this.scheduledFor,
    this.loggedAt,
    required this.status,
  });

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      regimenItemId: map['regimen_item_id'] as String,
      scheduledFor: DateTime.parse(map['scheduled_for'] as String).toLocal(),
      loggedAt: map['logged_at'] != null ? DateTime.parse(map['logged_at'] as String).toLocal() : null,
      status: DoseStatusX.fromDb(map['status'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'regimen_item_id': regimenItemId,
      'scheduled_for': scheduledFor.toUtc().toIso8601String(),
      'status': status.dbValue,
    };
  }
}
