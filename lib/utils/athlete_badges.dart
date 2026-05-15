import 'package:flutter/material.dart';

import '../models/athlete.dart';
import 'sinclair_utils.dart';

/// Odznaki zawodnika — ta sama logika co `AthleteBadges.vue` na WWW.
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

  int get level {
    var l = 0;
    for (final t in thresholds) {
      if (current >= t) l++;
    }
    return l;
  }

  double get progressPercent {
    final lv = level;
    if (lv >= thresholds.length) return 100;
    final prev = lv == 0 ? 0.0 : thresholds[lv - 1];
    final next = thresholds[lv];
    if (next <= prev) return 100;
    return ((current - prev) / (next - prev) * 100).clamp(0, 100);
  }

  double? get nextThreshold =>
      level < thresholds.length ? thresholds[level] : null;
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
  return SinclairCalculator.calculateTotal(t, bw, g);
}

List<AthleteBadgeDef> buildAthleteBadges(Athlete athlete, {int presentCount = 0}) {
  return [
    AthleteBadgeDef(
      id: 'sinclair',
      label: 'Mistrz Sinclaira',
      description:
          'Punkty Sinclair wyliczane na podstawie masy ciała i wyniku w dwuboju.',
      icon: Icons.emoji_events_outlined,
      accent: Colors.amber,
      current: _sinclair(athlete),
      thresholds: const [100, 200, 300, 400],
      unit: 'pkt',
    ),
    AthleteBadgeDef(
      id: 'total',
      label: 'Siła dwuboju',
      description: 'Suma najlepszego rwania i podrzutu.',
      icon: Icons.fitness_center_rounded,
      accent: Colors.green,
      current: athlete.totalKg ?? 0,
      thresholds: const [100, 200, 300, 400],
      unit: 'kg',
    ),
    AthleteBadgeDef(
      id: 'snatch',
      label: 'Technika rwania',
      description: 'Twój najlepszy wynik w rwaniu.',
      icon: Icons.bolt_rounded,
      accent: Colors.teal,
      current: athlete.bestSnatchKg ?? 0,
      thresholds: const [50, 90, 100, 120, 150],
      unit: 'kg',
    ),
    AthleteBadgeDef(
      id: 'cj',
      label: 'Moc podrzutu',
      description: 'Twój najlepszy wynik w podrzucie.',
      icon: Icons.local_fire_department_rounded,
      accent: Colors.deepOrange,
      current: athlete.bestCleanJerkKg ?? 0,
      thresholds: const [70, 90, 100, 120, 150, 170, 200],
      unit: 'kg',
    ),
    AthleteBadgeDef(
      id: 'trainings',
      label: 'Staż w klubie',
      description: 'Ilość obecności na treningach w systemie.',
      icon: Icons.calendar_month_rounded,
      accent: Colors.blue,
      current: presentCount.toDouble(),
      thresholds: const [10, 50, 100, 250, 500],
      unit: 'sesji',
    ),
  ];
}
