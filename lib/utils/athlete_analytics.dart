import '../models/athlete.dart';
import '../models/auth.dart';
import 'athlete_sinclair_bodyweight.dart';
import 'sinclair_utils.dart';

class AthleteChartPoint {
  final String date;
  final double total;
  final double snatch;
  final double cleanAndJerk;
  final double? sinclair;

  const AthleteChartPoint({
    required this.date,
    required this.total,
    required this.snatch,
    required this.cleanAndJerk,
    this.sinclair,
  });
}

class CombinedChartPoint {
  final String date;
  final double total;
  final double snatch;
  final double cleanAndJerk;
  final double? sinclair;
  final String kind;

  const CombinedChartPoint({
    required this.date,
    required this.total,
    required this.snatch,
    required this.cleanAndJerk,
    this.sinclair,
    required this.kind,
  });
}

class AthleteAnalyticsStats {
  final int competitions;
  final int trainings;
  final double? bestCompetitionTotal;
  final double? bestTrainingTotal;
  final double? bestCombinedTotal;
  final double? bestSnatch;
  final double? bestCleanJerk;
  final double? avgCompetitionTotal;
  final double? avgTrainingTotal;
  final double? bestSinclairCompetition;
  final double? bestSinclairTraining;
  final double? formRealisationPct;
  final double? trendKgLast90Days;
  final int pbCount;
  final int? daysSinceLastEntry;
  final String? lastEntryKind;

  const AthleteAnalyticsStats({
    required this.competitions,
    required this.trainings,
    this.bestCompetitionTotal,
    this.bestTrainingTotal,
    this.bestCombinedTotal,
    this.bestSnatch,
    this.bestCleanJerk,
    this.avgCompetitionTotal,
    this.avgTrainingTotal,
    this.bestSinclairCompetition,
    this.bestSinclairTraining,
    this.formRealisationPct,
    this.trendKgLast90Days,
    required this.pbCount,
    this.daysSinceLastEntry,
    this.lastEntryKind,
  });
}

bool _approved(CompetitionResult r) => r.status == 'Approved';

bool _isCompetition(CompetitionResult r) => r.kind != 'training';

SinclairGender? _sinclairGender(Athlete a) {
  if (a.gender == 'male') return SinclairGender.male;
  if (a.gender == 'female') return SinclairGender.female;
  return null;
}

double? _sinclairForTotal(Athlete a, double totalKg) {
  if (totalKg <= 0) return null;
  final sg = _sinclairGender(a);
  final eff = effectiveBodyweightKgForSinclair(
    bodyweight: a.bodyweight,
    weightCategory: a.weightCategory,
  );
  if (sg == null || eff <= 0) return null;
  final c = SinclairCalculator.calculateTotal(totalKg, eff, sg);
  if (!c.isFinite || c <= 0) return null;
  return double.parse(c.toStringAsFixed(2));
}

CombinedChartPoint _toCombinedPoint(
  Athlete a,
  CompetitionResult r,
  String kind,
) {
  final raw = r.date;
  final dateShort = raw.length >= 10 ? raw.substring(0, 10) : raw;
  return CombinedChartPoint(
    date: dateShort,
    total: r.total,
    snatch: r.snatch ?? 0,
    cleanAndJerk: r.cleanAndJerk ?? 0,
    sinclair: _sinclairForTotal(a, r.total),
    kind: kind,
  );
}

/// Starty z zawodów — zatwierdzone (jak `approvedResults` na WWW).
List<CompetitionResult> approvedCompetitionResults(
  List<CompetitionResult> raw,
) {
  return raw.where((r) => _approved(r) && _isCompetition(r)).toList();
}

/// Wpisy treningowe — zatwierdzone.
List<CompetitionResult> approvedTrainingResults(List<CompetitionResult> raw) {
  return raw.where((r) => _approved(r) && r.kind == 'training').toList();
}

/// Seria pod wykres „progres dwuboju” (tylko zawody).
List<AthleteChartPoint> buildProgressSeries(
  Athlete athlete,
  List<CompetitionResult> competitionApprovedSorted,
) {
  final rows = competitionApprovedSorted.where((r) => r.total > 0).toList()
    ..sort((x, y) => x.date.compareTo(y.date));
  return rows
      .map(
        (r) => AthleteChartPoint(
          date: r.date.length >= 10 ? r.date.substring(0, 10) : r.date,
          total: r.total,
          snatch: r.snatch ?? 0,
          cleanAndJerk: r.cleanAndJerk ?? 0,
          sinclair: _sinclairForTotal(athlete, r.total),
        ),
      )
      .toList();
}

/// Zawody + trening na jednej osi czasu (jak `combinedSeries` na WWW).
List<CombinedChartPoint> buildCombinedSeries(
  Athlete athlete,
  List<CompetitionResult> competitionApproved,
  List<CompetitionResult> trainingApproved,
  bool includeTraining,
) {
  final compPts = competitionApproved
      .map((r) => _toCombinedPoint(athlete, r, 'competition'))
      .toList();
  final trainPts = includeTraining
      ? trainingApproved
            .map((r) => _toCombinedPoint(athlete, r, 'training'))
            .toList()
      : <CombinedChartPoint>[];
  final all = [...compPts, ...trainPts]
    ..sort((a, b) => a.date.compareTo(b.date));
  return all;
}

double? _safeMax(List<double> values) {
  final v = values.where((e) => e.isFinite && e > 0).toList();
  if (v.isEmpty) return null;
  return v.reduce((a, b) => a > b ? a : b);
}

double? _safeAvg(List<double> values) {
  final v = values.where((e) => e.isFinite && e > 0).toList();
  if (v.isEmpty) return null;
  return double.parse(
    (v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1),
  );
}

double? _bestSinclairOfRows(Athlete a, List<CompetitionResult> rows) {
  double best = 0;
  for (final r in rows) {
    if (!_approved(r) || r.total <= 0) continue;
    final s = _sinclairForTotal(a, r.total);
    if (s != null && s > best) best = s;
  }
  return best > 0 ? double.parse(best.toStringAsFixed(2)) : null;
}

class PublicStartStats {
  final int totalStarts;
  final double? bestTotal;
  final double? avgTotal;
  final int? daysSinceLast;

  const PublicStartStats({
    required this.totalStarts,
    this.bestTotal,
    this.avgTotal,
    this.daysSinceLast,
  });
}

PublicStartStats computePublicStartStats(List<CompetitionResult> compApproved) {
  if (compApproved.isEmpty) {
    return const PublicStartStats(
      totalStarts: 0,
      bestTotal: null,
      avgTotal: null,
      daysSinceLast: null,
    );
  }
  final sorted = [...compApproved]..sort((a, b) => a.date.compareTo(b.date));
  final last = sorted.last;
  final totals = compApproved
      .map((r) => r.total)
      .where((t) => t > 0 && t.isFinite)
      .toList();
  final dStr = last.date.length >= 10 ? last.date.substring(0, 10) : last.date;
  final lastDt = DateTime.tryParse('${dStr}T00:00:00');
  int? daysSince;
  if (lastDt != null) {
    daysSince = DateTime.now().difference(lastDt).inDays.clamp(0, 99999);
  }
  return PublicStartStats(
    totalStarts: compApproved.length,
    bestTotal: totals.isEmpty ? null : totals.reduce((a, b) => a > b ? a : b),
    avgTotal: totals.isEmpty
        ? null
        : double.parse(
            (totals.reduce((a, b) => a + b) / totals.length).toStringAsFixed(1),
          ),
    daysSinceLast: daysSince,
  );
}

AthleteAnalyticsStats computeAthleteAnalyticsStats(
  Athlete athlete,
  List<CompetitionResult> compApproved,
  List<CompetitionResult> trainApproved,
  List<CombinedChartPoint> combinedSorted,
) {
  final compTotals = compApproved
      .map((r) => r.total)
      .where((t) => t.isFinite && t > 0)
      .toList();
  final trainTotals = trainApproved
      .map((r) => r.total)
      .where((t) => t.isFinite && t > 0)
      .toList();
  final allRows = [...compApproved, ...trainApproved];
  final allSnatch = allRows
      .map((r) => r.snatch ?? 0)
      .where((v) => v > 0)
      .toList();
  final allCj = allRows
      .map((r) => r.cleanAndJerk ?? 0)
      .where((v) => v > 0)
      .toList();

  final bestComp = _safeMax(compTotals);
  final bestTrain = _safeMax(trainTotals);
  final bestCombined = _safeMax([...compTotals, ...trainTotals]);

  var pbCount = 0;
  var runningMax = 0.0;
  for (final pt in combinedSorted) {
    if (pt.total > runningMax) {
      if (runningMax > 0) pbCount++;
      runningMax = pt.total;
    }
  }

  double? trendKgLast90Days;
  if (combinedSorted.length >= 4) {
    final last = combinedSorted.last;
    final lastDate = DateTime.tryParse('${last.date}T00:00:00');
    if (lastDate != null) {
      final cutoff = lastDate.subtract(const Duration(days: 90));
      final prev = lastDate.subtract(const Duration(days: 180));
      final recent = combinedSorted.where((p) {
        final t = DateTime.tryParse('${p.date}T00:00:00');
        return t != null && !t.isBefore(cutoff);
      }).toList();
      final earlier = combinedSorted.where((p) {
        final t = DateTime.tryParse('${p.date}T00:00:00');
        return t != null && !t.isBefore(prev) && t.isBefore(cutoff);
      }).toList();
      if (recent.isNotEmpty && earlier.isNotEmpty) {
        final a = recent.fold<double>(0, (s, x) => s + x.total) / recent.length;
        final b =
            earlier.fold<double>(0, (s, x) => s + x.total) / earlier.length;
        trendKgLast90Days = double.parse((a - b).toStringAsFixed(1));
      }
    }
  }

  int? daysSinceLastEntry;
  String? lastEntryKind;
  if (combinedSorted.isNotEmpty) {
    final lastPoint = combinedSorted.last;
    final t = DateTime.tryParse('${lastPoint.date}T00:00:00');
    if (t != null) {
      daysSinceLastEntry = DateTime.now().difference(t).inDays.clamp(0, 99999);
      lastEntryKind = lastPoint.kind;
    }
  }

  final formRealisationPct =
      (bestComp != null && bestTrain != null && bestTrain > 0)
      ? double.parse(((bestComp / bestTrain) * 100).toStringAsFixed(1))
      : null;

  return AthleteAnalyticsStats(
    competitions: compApproved.length,
    trainings: trainApproved.length,
    bestCompetitionTotal: bestComp,
    bestTrainingTotal: bestTrain,
    bestCombinedTotal: bestCombined,
    bestSnatch: _safeMax(allSnatch),
    bestCleanJerk: _safeMax(allCj),
    avgCompetitionTotal: _safeAvg(compTotals),
    avgTrainingTotal: _safeAvg(trainTotals),
    bestSinclairCompetition: _bestSinclairOfRows(athlete, compApproved),
    bestSinclairTraining: trainApproved.isEmpty
        ? null
        : _bestSinclairOfRows(athlete, trainApproved),
    formRealisationPct: formRealisationPct,
    trendKgLast90Days: trendKgLast90Days,
    pbCount: pbCount,
    daysSinceLastEntry: daysSinceLastEntry,
    lastEntryKind: lastEntryKind,
  );
}

/// KPI z najlepszego startu z zawodów (jak `competitionPbDisplay` na WWW).
({double? snatch, double? cleanJerk, double? total}) competitionPbDisplay(
  Athlete athlete,
  List<CompetitionResult> compApproved,
) {
  CompetitionResult? best;
  for (final r in compApproved) {
    if (r.total <= 0) continue;
    if (best == null ||
        r.total > best.total ||
        (r.total == best.total && r.date.compareTo(best.date) > 0)) {
      best = r;
    }
  }
  if (best == null) {
    return (
      snatch: athlete.bestSnatchKg,
      cleanJerk: athlete.bestCleanJerkKg,
      total: athlete.totalKg,
    );
  }
  return (snatch: best.snatch, cleanJerk: best.cleanAndJerk, total: best.total);
}
