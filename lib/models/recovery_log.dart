class RecoveryLog {
  final String id;
  final String athleteId;
  final String date;
  final double sleepHours;
  final int fatigueLevel;
  final int sorenessLevel;
  final int readinessLevel;
  final String? note;
  final String createdAt;

  RecoveryLog({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.sleepHours,
    required this.fatigueLevel,
    required this.sorenessLevel,
    required this.readinessLevel,
    this.note,
    required this.createdAt,
  });

  factory RecoveryLog.fromJson(Map<String, dynamic> json) {
    return RecoveryLog(
      id: json['id'] as String,
      athleteId: json['athlete_id'] as String,
      date: json['date'] as String,
      sleepHours: (json['sleep_hours'] as num).toDouble(),
      fatigueLevel: (json['fatigue_level'] as num).toInt(),
      sorenessLevel: (json['soreness_level'] as num).toInt(),
      readinessLevel: (json['readiness_level'] as num).toInt(),
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}
