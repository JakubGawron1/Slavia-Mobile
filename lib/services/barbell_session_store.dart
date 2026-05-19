import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/barbell_path_analysis.dart';

/// Lokalna historia analiz toru (offline, bez synchronizacji z backendem).
class BarbellSessionRecord {
  BarbellSessionRecord({
    required this.id,
    required this.createdAt,
    required this.videoName,
    required this.samples,
    required this.stabilityScore,
    required this.trajectoryLength,
    required this.framesWithPose,
  });

  final String id;
  final DateTime createdAt;
  final String videoName;
  final List<BarbellSample> samples;
  final double stabilityScore;
  final double trajectoryLength;
  final int framesWithPose;

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'video_name': videoName,
        'stability_score': stabilityScore,
        'trajectory_length': trajectoryLength,
        'frames_with_pose': framesWithPose,
        'samples': samples
            .map(
              (s) => {
                't': s.t,
                'barX': s.barX,
                'barY': s.barY,
                'hipMidX': s.hipMidX,
                'shoulderMidX': s.shoulderMidX,
              },
            )
            .toList(),
      };

  factory BarbellSessionRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['samples'] as List<dynamic>? ?? [];
    return BarbellSessionRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      videoName: json['video_name'] as String? ?? 'Nagranie',
      stabilityScore: (json['stability_score'] as num?)?.toDouble() ?? 0,
      trajectoryLength: (json['trajectory_length'] as num?)?.toDouble() ?? 0,
      framesWithPose: json['frames_with_pose'] as int? ?? 0,
      samples: raw
          .map(
            (e) => BarbellSample(
              t: (e['t'] as num).toDouble(),
              barX: (e['barX'] as num).toDouble(),
              barY: (e['barY'] as num).toDouble(),
              hipMidX: (e['hipMidX'] as num).toDouble(),
              shoulderMidX: (e['shoulderMidX'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}

class BarbellSessionStore {
  BarbellSessionStore._();
  static final BarbellSessionStore instance = BarbellSessionStore._();

  static const _key = 'slavia_barbell_sessions_v1';
  static const _maxSessions = 24;

  Future<List<BarbellSessionRecord>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BarbellSessionRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(BarbellSessionRecord session) async {
    final existing = await list();
    final next = [session, ...existing.where((s) => s.id != session.id)]
        .take(_maxSessions)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final existing = await list();
    final next = existing.where((s) => s.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }
}
