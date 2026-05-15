class AttendanceSummary {
  final String athleteId;
  final int presentCount;
  final int absentCount;
  final int pendingCount;
  final double attendancePercent;

  AttendanceSummary({
    required this.athleteId,
    required this.presentCount,
    required this.absentCount,
    required this.pendingCount,
    required this.attendancePercent,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      athleteId: json['athlete_id'] as String,
      presentCount: (json['present_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      attendancePercent: (json['attendance_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}
