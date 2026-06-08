import 'package:flutter/material.dart';
import 'package:slavia_shared/athlete_badge_catalog.dart';
import 'package:slavia_shared/badge_helpers.dart';

import '../models/athlete.dart';
import 'sinclair_utils.dart';

/// Odznaki zawodnika — metadane z `@slavia/shared`, logika poziomów współdzielona.
class AthleteBadgeDef {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final double current;
  final List<double> thresholds;
  final String unit;

  const AthleteBadgeDef({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.current,
    required this.thresholds,
    required this.unit,
  });

  int get level => getBadgeLevel(BadgeThresholds(thresholds: thresholds, current: current));

  double get progressPercent =>
      getBadgeProgressPercent(BadgeThresholds(thresholds: thresholds, current: current));

  double? get nextThreshold =>
      getNextBadgeThreshold(BadgeThresholds(thresholds: thresholds, current: current));
}

SinclairGender? _gender(Athlete a) {
  final g = a.gender?.toLowerCase();
  if (g == 'female' || g == 'k') return SinclairGender.female;
  if (g == 'male' || g == 'm') return SinclairGender.male;
  return null;
}

double _sinclair(Athlete a) {
  final g = _gender(a);
  final bw = a.bodyweight;
  final t = a.totalKg;
  if (g == null || bw == null || bw <= 0 || t == null || t <= 0) return 0;
  final v = SinclairCalculator.calculateTotal(t, bw, g);
  return v.isNaN ? 0 : v;
}

double _currentForBadge(String id, Athlete athlete, int presentCount) {
  return switch (id) {
    'sinclair' => _sinclair(athlete),
    'total' => athlete.totalKg ?? 0,
    'snatch' => athlete.bestSnatchKg ?? 0,
    'cj' => athlete.bestCleanJerkKg ?? 0,
    'trainings' => presentCount.toDouble(),
    _ => 0,
  };
}

(IconData, Color) _iconForBadge(String id) {
  return switch (id) {
    'sinclair' => (Icons.emoji_events_outlined, Colors.amber),
    'total' => (Icons.fitness_center_rounded, Colors.green),
    'snatch' => (Icons.bolt_rounded, Colors.teal),
    'cj' => (Icons.local_fire_department_rounded, Colors.deepOrange),
    'trainings' => (Icons.calendar_month_rounded, Colors.blue),
    _ => (Icons.star_outline, Colors.grey),
  };
}

List<AthleteBadgeDef> buildAthleteBadges(Athlete athlete, {int presentCount = 0}) {
  return [
    for (final meta in AthleteBadgeCatalog.badges)
      () {
        final (icon, accent) = _iconForBadge(meta.id);
        return AthleteBadgeDef(
          id: meta.id,
          label: meta.label,
          description: meta.description,
          icon: icon,
          accent: accent,
          current: _currentForBadge(meta.id, athlete, presentCount),
          thresholds: meta.thresholds,
          unit: meta.unit,
        );
      }(),
  ];
}
