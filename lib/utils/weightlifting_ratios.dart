enum ExerciseId {
  snatch,
  cleanJerk,
  powerSnatch,
  powerClean,
  powerJerk,
  backSquat,
  frontSquat,
  snatchSquat,
  snatchPull,
  cleanPull,
  deadlift,
  strictPress,
  pushPress,
  snatchPushPress,
  splitJerkFront,
  splitJerkBack,
  snatchPress,
  cleanFromBlocks,
  snatchFromBlocks,
  powerSnatchBalance,
}

class RatioRange {
  final double min;
  final double max;
  final String source;
  final bool heuristic;

  const RatioRange({
    required this.min,
    required this.max,
    required this.source,
    this.heuristic = false,
  });
}

class ExerciseDef {
  final ExerciseId id;
  final String pl;
  final ExerciseId from;
  final RatioRange ratio;
  final String? adviceBelow;
  final String? adviceAbove;

  const ExerciseDef({
    required this.id,
    required this.pl,
    required this.from,
    required this.ratio,
    this.adviceBelow,
    this.adviceAbove,
  });
}

class WeightliftingRatios {
  static const List<ExerciseDef> exercises = [
    ExerciseDef(
      id: ExerciseId.snatch,
      pl: 'Rwanie',
      from: ExerciseId.snatch,
      ratio: RatioRange(min: 1, max: 1, source: 'Wartość bazowa'),
    ),
    ExerciseDef(
      id: ExerciseId.cleanJerk,
      pl: 'Podrzut',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(min: 1, max: 1, source: 'Wartość bazowa'),
    ),
    ExerciseDef(
      id: ExerciseId.backSquat,
      pl: 'Przysiad z tyłu',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(min: 1 / 0.85, max: 1 / 0.75, source: 'C&J ≈ 75–85% back squat'),
      adviceBelow: 'Jeśli przysiad z tyłu odstaje, często najszybciej działa plan siłowy.',
      adviceAbove: 'Jeśli przysiad jest bardzo mocny, a podrzut stoi, brakuje transferu technicznego.',
    ),
    ExerciseDef(
      id: ExerciseId.frontSquat,
      pl: 'Przysiad z przodu',
      from: ExerciseId.backSquat,
      ratio: RatioRange(min: 0.85, max: 0.93, source: 'Front squat ≈ 85–93% back squat'),
      adviceBelow: 'Popracuj nad pozycją rack i siłą czwórek.',
      adviceAbove: 'Świetny „clean engine”. Skup się na dynamice wstania.',
    ),
    ExerciseDef(
      id: ExerciseId.snatchSquat,
      pl: 'Przysiad rwaniowy',
      from: ExerciseId.snatch,
      ratio: RatioRange(min: 0.95, max: 1.05, source: 'Overhead squat ~ 100% snatch'),
    ),
    ExerciseDef(
      id: ExerciseId.powerSnatch,
      pl: 'Rwanie siłowe',
      from: ExerciseId.snatch,
      ratio: RatioRange(min: 0.80, max: 0.85, source: 'Power snatch ≈ 80–85% snatch'),
    ),
    ExerciseDef(
      id: ExerciseId.powerClean,
      pl: 'Zarzut siłowy',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(min: 0.85, max: 0.90, source: 'Power clean ≈ 88% C&J'),
    ),
    // Add more as needed, I'll add a few more key ones
    ExerciseDef(
      id: ExerciseId.pushPress,
      pl: 'Wycisko-podrzut',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(min: 0.60, max: 0.75, source: 'Push press ≈ 75–85% jerk', heuristic: true),
    ),
  ];

  static Map<ExerciseId, String> get names => {for (var e in exercises) e.id: e.pl};

  static List<RatioResult> compute(Map<ExerciseId, double?> inputs) {
    final results = <RatioResult>[];
    
    for (final e in exercises) {
      if (e.id == e.from) continue;
      
      final base = inputs[e.from];
      final actual = inputs[e.id];
      
      double? minKg;
      double? maxKg;
      double? actualPct;
      String status = 'unknown';
      String? note;

      if (base != null && base > 0) {
        minKg = base * e.ratio.min;
        maxKg = base * e.ratio.max;
        
        if (actual != null && actual > 0) {
          actualPct = (actual / base) * 100;
          if (actualPct < e.ratio.min * 100) {
            status = 'below';
          } else if (actualPct > e.ratio.max * 100) {
            status = 'above';
          } else {
            status = 'in_range';
          }
          note = _buildNote(status, e.pl, names[e.from]!, actualPct, e.ratio.min * 100, e.ratio.max * 100, e.adviceBelow, e.adviceAbove);
        }
      }
      
      results.add(RatioResult(
        id: e.id,
        pl: e.pl,
        fromPl: names[e.from]!,
        minKg: minKg,
        maxKg: maxKg,
        actualKg: actual,
        actualPct: actualPct,
        status: status,
        note: note,
        ratioSource: e.ratio.source,
      ));
    }
    
    return results;
  }

  static String _buildNote(String status, String ex, String base, double actual, double min, double max, String? below, String? above) {
    final rangeStr = '${min.round()}–${max.round()}%';
    final actualStr = '${actual.round()}%';
    if (status == 'in_range') return 'Super — $ex jest w widełkach względem $base ($actualStr vs $rangeStr).';
    if (status == 'below') return '$ex jest poniżej zakresu względem $base ($actualStr vs $rangeStr). ${below ?? ""}';
    return '$ex jest powyżej zakresu względem $base ($actualStr vs $rangeStr). ${above ?? ""}';
  }
}

class RatioResult {
  final ExerciseId id;
  final String pl;
  final String fromPl;
  final double? minKg;
  final double? maxKg;
  final double? actualKg;
  final double? actualPct;
  final String status;
  final String? note;
  final String ratioSource;

  RatioResult({
    required this.id,
    required this.pl,
    required this.fromPl,
    this.minKg,
    this.maxKg,
    this.actualKg,
    this.actualPct,
    required this.status,
    this.note,
    required this.ratioSource,
  });
}
