import '../models/athlete.dart';

/// Liczy aktualną serię dni z wpisem w dzienniku (kalendarzowe dni lokalne).
/// Idea #168 — delikatna motywacja, bez kar za przerwy w UI.
int computeTrainingLogStreak(List<TrainingLogEntry> entries) {
  if (entries.isEmpty) return 0;
  final days = <DateTime>{};
  for (final e in entries) {
    try {
      final d = DateTime.parse(e.sessionDate);
      days.add(DateTime(d.year, d.month, d.day));
    } catch (_) {}
  }
  if (days.isEmpty) return 0;

  final today = DateTime.now();
  final todayD = DateTime(today.year, today.month, today.day);
  final yesterdayD = todayD.subtract(const Duration(days: 1));

  DateTime cursor;
  if (days.contains(todayD)) {
    cursor = todayD;
  } else if (days.contains(yesterdayD)) {
    cursor = yesterdayD;
  } else {
    return 0;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
