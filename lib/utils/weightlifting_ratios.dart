// „Złote proporcje” — port logiki z Slavia-frontend `weightliftingRatios.ts`
// (widełki + krawędzie odwrotne + te same notatki co na WWW).

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

class _RatioEdge {
  final ExerciseId to;
  final ExerciseId from;
  final RatioRange ratio;
  final String? adviceBelow;
  final String? adviceAbove;

  const _RatioEdge({
    required this.to,
    required this.from,
    required this.ratio,
    this.adviceBelow,
    this.adviceAbove,
  });
}

/// Wynik pojedynczej relacji (jak `RatioResult` w TS).
class RatioResult {
  final ExerciseId id;
  final String pl;
  final ExerciseId fromId;
  final String fromPl;
  final double? minKg;
  final double? maxKg;
  final RatioRange ratio;
  final double? actualKg;
  final double? actualPct;
  /// `unknown` | `in_range` | `below` | `above`
  final String status;
  final String? note;

  RatioResult({
    required this.id,
    required this.pl,
    required this.fromId,
    required this.fromPl,
    this.minKg,
    this.maxKg,
    required this.ratio,
    this.actualKg,
    this.actualPct,
    required this.status,
    this.note,
  });
}

abstract final class WeightliftingRatios {
  WeightliftingRatios._();

  /// Katalog ćwiczeń (wartości bazowe + relacje) — zgodnie z WWW.
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
      ratio: RatioRange(
        min: 1 / 0.85,
        max: 1 / 0.75,
        source: 'C&J ≈ 75–85% back squat (benchmarki ratio)',
      ),
      adviceBelow:
          'Jeśli przysiad z tyłu odstaje, często najszybciej działa plan siłowy (progresja 3–6 tygodni) + spokojna objętość na nogi i grzbiet. Technika w C&J zwykle rośnie „sama”, gdy masz mocny fundament.',
      adviceAbove:
          'Jeśli przysiad jest bardzo mocny, a podrzut stoi, to dobry znak — masz siłę. Najczęściej brakuje transferu: praca nad techniką (szczególnie clean i jerk), szybkość pod sztangę i stabilizacja nad głową.',
    ),
    ExerciseDef(
      id: ExerciseId.frontSquat,
      pl: 'Przysiad z przodu',
      from: ExerciseId.backSquat,
      ratio: RatioRange(
        min: 0.85,
        max: 0.93,
        source: 'Front squat ≈ 85–93% back squat (ratio)',
      ),
      adviceBelow:
          'Gdy przysiad z przodu jest niski względem tyłu, zwykle pomaga praca nad pozycją rack (mobilność + stabilizacja) i siłą czwórek. Dodaj pauzy na dole i spokojne serie 3–5.',
      adviceAbove:
          'Jeśli front squat jest bardzo blisko back squatu, to świetny „clean engine”. Żeby przełożyć to na wynik, skup się na dynamice wejścia pod sztangę i jakości pozycji wstania z ciężkiego zarzutu.',
    ),
    ExerciseDef(
      id: ExerciseId.snatchSquat,
      pl: 'Przysiad rwaniowy',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 0.95,
        max: 1.05,
        source: 'Overhead squat ~ 100% snatch (gold standards)',
      ),
      adviceBelow:
          'Jeśli przysiad rwaniowy odstaje, to najczęściej kwestia mobilności/stabilizacji nad głową. Dobrze działają OHS w tempie, pauzy w dole i praca nad „zamkniętym” barkiem (rotatory + łopatka).',
      adviceAbove:
          'Mocny OHS to super baza. Jeśli rwanie nie nadąża, zwykle warto dołożyć technikę: timing podbicia, stabilne przyjęcie i szybkość zejścia pod sztangę.',
    ),
    ExerciseDef(
      id: ExerciseId.powerSnatchBalance,
      pl: 'Wybijanie do rwania',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 1.00,
        max: 1.10,
        source:
            'Snatch balance ~ 105% snatch (gold standards) + widełki',
      ),
      adviceBelow:
          'Jeśli snatch balance jest niski, zwykle brakuje pewności w przyjęciu i stabilizacji. Pomaga praca nad „lockoutem”, drop snatch i serie z pauzą w dole (kontrola).',
      adviceAbove:
          'Jeśli snatch balance jest wyraźnie mocniejszy, masz świetną stabilizację. Żeby przenieść to na rwanie, skup się na jakości ciągu i tym, żeby „wjeżdżać pod sztangę”, a nie ciągnąć jej w górę.',
    ),
    ExerciseDef(
      id: ExerciseId.powerSnatch,
      pl: 'Rwanie siłowe',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 0.80,
        max: 0.85,
        source: 'Praktyczne widełki: power snatch ≈ 80–85% snatch',
      ),
      adviceBelow:
          'Jeśli rwanie siłowe jest nisko, często brakuje „mocy” w drugiej fazie (biodra) albo odwagi w szybkim dociągnięciu łokci. Dobrze działają high pulls, hang power snatch i praca nad tempem.',
      adviceAbove:
          'Jeśli power snatch jest bardzo blisko pełnego rwania, to zwykle znak, że warto popracować nad zejściem pod sztangę (szybkość i pewność przyjęcia) — wtedy pełne rwanie dogoni power.',
    ),
    ExerciseDef(
      id: ExerciseId.powerClean,
      pl: 'Zarzut siłowy',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 0.85,
        max: 0.90,
        source: 'Power clean ≈ 88% C&J (gold standards) + widełki',
      ),
      adviceBelow:
          'Niski power clean zwykle oznacza brak dynamiki w wybiciu albo słabszą pozycję startową. Pomaga praca z bloków/hangu i szybkie serie na jakości (bez „ciągnięcia plecami”).',
      adviceAbove:
          'Jeśli power clean jest mocny, a C&J stoi, często ogranicza Cię jerk albo wstawanie z pełnego zarzutu (front squat / pozycja rack).',
    ),
    ExerciseDef(
      id: ExerciseId.powerJerk,
      pl: 'Wybijanie siłowe (power jerk)',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 0.90,
        max: 1.05,
        source:
            'Zależne od tego czy limituje clean czy jerk — widełki praktyczne',
        heuristic: true,
      ),
      adviceBelow:
          'Jeśli power jerk odstaje, często pomaga praca nad dip&drive (pionowy tor) i stabilizacją nad głową: push press, jerk balances, krótkie serie techniczne.',
      adviceAbove:
          'Jeśli power jerk jest mocny, a C&J stoi, to świetnie — zostaje dopiąć clean (wejście pod sztangę) lub przejście z clean do jerk (ustawienie stóp/oddech).',
    ),
    ExerciseDef(
      id: ExerciseId.snatchPull,
      pl: 'Ciągi do rwania',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 0.90,
        max: 1.15,
        source: 'Typowe widełki treningowe dla pulls',
        heuristic: true,
      ),
      adviceBelow:
          'Jeśli ciągi do rwania są nisko, dołóż spokojnie siłę w pierwszym ciągu: tempo pulls, zatrzymania pod kolanem i kontrola pozycji pleców.',
      adviceAbove:
          'Jeśli ciągi są bardzo mocne, a rwanie stoi, to sygnał że „siła jest” — priorytetem staje się technika (kontakt z udem, timing, zejście pod sztangę).',
    ),
    ExerciseDef(
      id: ExerciseId.cleanPull,
      pl: 'Ciągi do podrzutu',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 1.00,
        max: 1.25,
        source: 'Typowe widełki treningowe dla clean pulls',
        heuristic: true,
      ),
      adviceBelow:
          'Jeśli clean pulls odstają, zwykle pomaga praca nad pozycją pleców i nogami: tempo, pauzy, utrzymanie barków nad sztangą.',
      adviceAbove:
          'Jeśli clean pulls są bardzo mocne, a podrzut stoi, to często ogranicza clean w przyjęciu (rack, szybkość wejścia) albo jerk.',
    ),
    ExerciseDef(
      id: ExerciseId.deadlift,
      pl: 'Martwy ciąg',
      from: ExerciseId.backSquat,
      ratio: RatioRange(
        min: 1.00,
        max: 1.20,
        source:
            'Back squat : deadlift ~ 80% (czyli deadlift ~ 1.25× BS) — antropometria mocno wpływa',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.pushPress,
      pl: 'Wycisko-podrzut',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 0.60,
        max: 0.75,
        source:
            'Push press ≈ 75–85% jerk; jerk zwykle ≳ C&J (widełki)',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.strictPress,
      pl: 'Wyciskanie żołnierskie',
      from: ExerciseId.pushPress,
      ratio: RatioRange(
        min: 0.70,
        max: 0.75,
        source: 'Strict press ≈ 70–75% push press (ratio)',
      ),
      adviceBelow:
          'Jeśli strict press jest nisko względem push press, warto dołożyć trochę czystej siły barków i tricepsa (serie 5–8, kontrola, brak odbicia). To później stabilizuje też jerk.',
      adviceAbove:
          'Jeśli strict press jest bardzo wysoki, masz świetną siłę góry. Jeśli jerk nie nadąża, zwykle brakuje pracy nóg i timing’u dip&drive.',
    ),
    ExerciseDef(
      id: ExerciseId.snatchPushPress,
      pl: 'Wycisko-wybijanie rwaniowe (chwyt rwaniowy)',
      from: ExerciseId.pushPress,
      ratio: RatioRange(
        min: 0.85,
        max: 1.05,
        source:
            'Snatch-grip zwykle trochę słabszy od klasycznego push press (widełki)',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.splitJerkFront,
      pl: 'Wybijanie w nożyce z przodu',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 0.95,
        max: 1.10,
        source: 'Zależne od limitu clean vs jerk — widełki praktyczne',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.splitJerkBack,
      pl: 'Wybijanie w nożyce z tyłu (sztanga leży na barkach)',
      from: ExerciseId.splitJerkFront,
      ratio: RatioRange(
        min: 0.95,
        max: 1.05,
        source: 'BTN bywa podobne lub minimalnie mocniejsze (widełki)',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.snatchPress,
      pl: 'Wyciskanie rwaniowe',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 0.40,
        max: 0.55,
        source:
            'Silnie zależne od mobilności/stabilizacji; orientacyjne widełki',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.cleanFromBlocks,
      pl: 'Zarzut z bloków',
      from: ExerciseId.cleanJerk,
      ratio: RatioRange(
        min: 0.90,
        max: 1.05,
        source: 'Bloki pozwalają czasem „dobić” technicznie; widełki praktyczne',
        heuristic: true,
      ),
    ),
    ExerciseDef(
      id: ExerciseId.snatchFromBlocks,
      pl: 'Rwanie z bloków',
      from: ExerciseId.snatch,
      ratio: RatioRange(
        min: 0.90,
        max: 1.05,
        source: 'Bloki: zwykle 90–105% pełnego rwania (widełki)',
        heuristic: true,
      ),
    ),
  ];

  static Map<ExerciseId, String> get _nameById => {
        for (final e in exercises) e.id: e.pl,
      };

  static RatioRange? _invertRatio(RatioRange r) {
    if (!r.min.isFinite || !r.max.isFinite || r.min <= 0 || r.max <= 0) {
      return null;
    }
    final invMin = 1 / r.max;
    final invMax = 1 / r.min;
    if (!invMin.isFinite || !invMax.isFinite) return null;
    return RatioRange(
      min: invMin < invMax ? invMin : invMax,
      max: invMin > invMax ? invMin : invMax,
      source: 'Odwrócone: ${r.source}',
      heuristic: r.heuristic,
    );
  }

  static double _clampPct(double p) {
    if (p < 0) return 0;
    if (p > 999) return 999;
    return p;
  }

  static String _buildFriendlyNote({
    required String status,
    required String exercisePl,
    required String basePl,
    required double actualPct,
    required double minPct,
    required double maxPct,
    String? adviceBelow,
    String? adviceAbove,
  }) {
    final band =
        '${minPct.round()}–${maxPct.round()}%';
    final yours = '${actualPct.round()}%';

    if (status == 'in_range') {
      return 'Super — $exercisePl jest w typowych widełkach względem „$basePl” ($yours vs $band). Trzymaj ten balans i buduj spokojnie oba elementy.';
    }
    if (status == 'below') {
      return 'Spokojnie — $exercisePl jest trochę poniżej typowego zakresu względem „$basePl” ($yours vs $band). ${adviceBelow ?? 'Najczęściej pomaga konsekwentna praca nad słabym ogniwem: albo technika i timing, albo stabilizacja/mobilność w pozycjach.'}';
    }
    return 'To mocna strona — $exercisePl wypada powyżej typowego zakresu względem „$basePl” ($yours vs $band). ${adviceAbove ?? 'To świetnie, ale jeśli wynik w „$basePl” stoi w miejscu, warto dołożyć trochę pracy nad transferem (technika, szybkość zejścia, stabilizacja).'}';
  }

  /// Alias kompatybilności wstecznej.
  static List<RatioResult> compute(Map<ExerciseId, double?> inputs) =>
      computeRatios(inputs);

  static List<RatioResult> computeRatios(Map<ExerciseId, double?> inputs) {
    final nameById = _nameById;

    final forwardEdges = exercises
        .map(
          (e) => _RatioEdge(
            to: e.id,
            from: e.from,
            ratio: e.ratio,
            adviceBelow: e.adviceBelow,
            adviceAbove: e.adviceAbove,
          ),
        )
        .toList();

    final reverseEdges = <_RatioEdge>[];
    for (final e in forwardEdges) {
      if (e.to == e.from) continue;
      final inv = _invertRatio(e.ratio);
      if (inv == null) continue;
      reverseEdges.add(
        _RatioEdge(
          to: e.from,
          from: e.to,
          ratio: inv,
        ),
      );
    }

    final merged = <_RatioEdge>[...forwardEdges, ...reverseEdges];
    final edges = <_RatioEdge>[];
    for (var i = 0; i < merged.length; i++) {
      final e = merged[i];
      if (merged.indexWhere((x) => x.to == e.to && x.from == e.from) != i) {
        continue;
      }
      edges.add(e);
    }

    final out = <RatioResult>[];
    for (final e in edges) {
      if (e.to == e.from) continue;

      final baseRaw = inputs[e.from];
      final base = (baseRaw != null && baseRaw > 0) ? baseRaw : null;

      double? minKg;
      double? maxKg;
      if (base != null) {
        minKg = base * e.ratio.min;
        maxKg = base * e.ratio.max;
      }

      final actualRaw = inputs[e.to];
      final actual =
          (actualRaw != null && actualRaw > 0) ? actualRaw : null;

      double? actualPct;
      if (base != null && actual != null) {
        actualPct = _clampPct((actual / base) * 100);
      }

      final minPct = e.ratio.min * 100;
      final maxPct = e.ratio.max * 100;

      var status = 'unknown';
      String? note;
      if (actualPct != null) {
        if (actualPct < minPct) {
          status = 'below';
        } else if (actualPct > maxPct) {
          status = 'above';
        } else {
          status = 'in_range';
        }
        note = _buildFriendlyNote(
          status: status,
          exercisePl: nameById[e.to] ?? e.to.name,
          basePl: nameById[e.from] ?? e.from.name,
          actualPct: actualPct,
          minPct: minPct,
          maxPct: maxPct,
          adviceBelow: e.adviceBelow,
          adviceAbove: e.adviceAbove,
        );
      }

      out.add(
        RatioResult(
          id: e.to,
          pl: nameById[e.to] ?? e.to.name,
          fromId: e.from,
          fromPl: nameById[e.from] ?? e.from.name,
          minKg: minKg != null ? double.parse(minKg.toStringAsFixed(1)) : null,
          maxKg: maxKg != null ? double.parse(maxKg.toStringAsFixed(1)) : null,
          ratio: e.ratio,
          actualKg: actual,
          actualPct:
              actualPct != null ? double.parse(actualPct.toStringAsFixed(1)) : null,
          status: status,
          note: note,
        ),
      );
    }
    return out;
  }

  /// Kolejność pól jak na stronie WWW (`ALL_KEYS`).
  static const List<ExerciseId> allInputKeys = [
    ExerciseId.snatch,
    ExerciseId.cleanJerk,
    ExerciseId.backSquat,
    ExerciseId.frontSquat,
    ExerciseId.pushPress,
    ExerciseId.powerSnatch,
    ExerciseId.powerClean,
    ExerciseId.powerJerk,
    ExerciseId.snatchSquat,
    ExerciseId.snatchPull,
    ExerciseId.cleanPull,
    ExerciseId.deadlift,
    ExerciseId.strictPress,
    ExerciseId.snatchPushPress,
    ExerciseId.splitJerkFront,
    ExerciseId.splitJerkBack,
    ExerciseId.snatchPress,
    ExerciseId.cleanFromBlocks,
    ExerciseId.snatchFromBlocks,
    ExerciseId.powerSnatchBalance,
  ];

  static String labelFor(ExerciseId id) => _nameById[id] ?? id.name;
}
