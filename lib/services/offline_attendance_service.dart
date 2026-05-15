import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OfflineAttendanceRecord {
  final String athleteId;
  final String sessionDate;
  final String status;
  final String sourceRole;
  final String? note;
  final DateTime createdAt;

  OfflineAttendanceRecord({
    required this.athleteId,
    required this.sessionDate,
    required this.status,
    required this.sourceRole,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'athlete_id': athleteId,
    'session_date': sessionDate,
    'status': status,
    'source_role': sourceRole,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory OfflineAttendanceRecord.fromJson(Map<String, dynamic> json) => OfflineAttendanceRecord(
    athleteId: json['athlete_id'],
    sessionDate: json['session_date'],
    status: json['status'],
    sourceRole: json['source_role'],
    note: json['note'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class OfflineAttendanceService {
  static const String _kStorageKey = 'offline_attendance_queue';
  final ApiService _apiService;

  OfflineAttendanceService(this._apiService);

  Future<void> queueRecord(OfflineAttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_kStorageKey) ?? [];
    queue.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_kStorageKey, queue);
  }

  Future<int> getQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kStorageKey) ?? []).length;
  }

  Future<void> sync() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_kStorageKey) ?? [];
    if (queue.isEmpty) return;

    final List<String> failed = [];
    for (final item in queue) {
      try {
        final record = OfflineAttendanceRecord.fromJson(jsonDecode(item));
        // Note: We need a method in ApiService that supports custom created_at if possible,
        // or just accept that it will be marked as of "now" on the server.
        // For Slavia, upsertAttendance usually handles current day.
        // We'll use the standard upsert method.
        await _apiService.upsertAttendance(
          athleteId: record.athleteId,
          sessionDate: record.sessionDate,
          status: record.status,
          note: record.note,
        );
      } catch (e) {
        failed.add(item);
      }
    }

    await prefs.setStringList(_kStorageKey, failed);
  }
}
