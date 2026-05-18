// Tor sztangi — port heurystyk z `app/utils/barbellPathAnalysis.ts` (frontend Nuxt).
import 'dart:math' as math;

class BarbellSample {
  const BarbellSample({
    required this.t,
    required this.barX,
    required this.barY,
    required this.hipMidX,
    required this.shoulderMidX,
  });

  final double t;
  final double barX;
  final double barY;
  final double hipMidX;
  final double shoulderMidX;
}

class BarbellTechniqueMetrics {
  const BarbellTechniqueMetrics({
    required this.meanDeviation,
    required this.trajectoryLength,
    required this.stabilityScore,
    required this.maxVerticalSpeed,
    required this.maxHorizontalDeviation,
  });

  final double meanDeviation;
  final double trajectoryLength;
  final double stabilityScore;
  final double maxVerticalSpeed;
  final double maxHorizontalDeviation;

  static const empty = BarbellTechniqueMetrics(
    meanDeviation: 0,
    trajectoryLength: 0,
    stabilityScore: 0,
    maxVerticalSpeed: 0,
    maxHorizontalDeviation: 0,
  );
}

List<BarbellSample> smoothSamples(List<BarbellSample> samples, {int window = 3}) {
  if (samples.length < window) return samples;
  final half = window ~/ 2;
  final out = <BarbellSample>[];
  for (var i = 0; i < samples.length; i++) {
    final from = i - half < 0 ? 0 : i - half;
    final to = i + half >= samples.length ? samples.length - 1 : i + half;
    var sx = 0.0, sy = 0.0, hx = 0.0, sh = 0.0;
    var c = 0;
    for (var j = from; j <= to; j++) {
      final p = samples[j];
      sx += p.barX;
      sy += p.barY;
      hx += p.hipMidX;
      sh += p.shoulderMidX;
      c++;
    }
    final cur = samples[i];
    out.add(BarbellSample(
      t: cur.t,
      barX: sx / c,
      barY: sy / c,
      hipMidX: hx / c,
      shoulderMidX: sh / c,
    ));
  }
  return out;
}

List<BarbellSample> smoothSamplesForFps(List<BarbellSample> samples, {double fps = 30}) {
  final normalized = fps.isFinite
      ? fps.round().clamp(12, 120)
      : 30;
  final window = normalized <= 24 ? 3 : (normalized <= 50 ? 5 : 7);
  return smoothSamples(samples, window: window);
}

double _std(List<double> nums) {
  if (nums.length < 2) return 0;
  final m = nums.reduce((a, b) => a + b) / nums.length;
  final v = nums.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / nums.length;
  return math.sqrt(v);
}

List<String> buildBiomechanicalFeedback(List<BarbellSample> samples) {
  final msgs = <String>[];
  if (samples.length < 10) {
    msgs.add(
      'Za mało stabilnych klatek z widoczną sztangą. Użyj nagrania z profilu, '
      'dobrego światła i krótkiego klipu (kilka–kilkanaście sekund podejścia).',
    );
    return msgs;
  }

  final estimatedFps = samples.length >= 2
      ? ((samples.length - 1) /
              (samples.last.t - samples.first.t).clamp(0.001, double.infinity))
          .round()
          .clamp(12, 120)
      : 30;
  final smooth = smoothSamplesForFps(samples, fps: estimatedFps.toDouble());
  final relX = smooth.map((s) => s.barX - s.hipMidX).toList();
  final spread = smooth.map((s) => s.barX).reduce((a, b) => a > b ? a : b) -
      smooth.map((s) => s.barX).reduce((a, b) => a < b ? a : b);
  final verticalTravel = smooth.map((s) => s.barY).reduce((a, b) => a < b ? a : b) -
      smooth.map((s) => s.barY).reduce((a, b) => a > b ? a : b);
  final lateralStd = _std(smooth.map((s) => s.barX).toList());

  if (spread > 0.16) {
    msgs.add(
      'Tor ruchu jest zbyt szeroki w osi poziomej — kontroluj zbliżenie sztangi po udach.',
    );
  } else if (spread > 0.11) {
    msgs.add('Zauważalne „chodzenie” sztangi na boki — dopracuj zbliżenie i kontakt z nogami.');
  }

  if (lateralStd > 0.045) {
    msgs.add(
      'Nieregularny tor poziomy — dużo korekt na boki; zwolnij tempo kontaktu.',
    );
  }

  final maxForward = relX.map((x) => x.abs()).reduce((a, b) => a > b ? a : b);
  final forwardBias = relX.reduce((a, b) => a + b) / relX.length;

  if (maxForward > 0.085 || forwardBias > 0.035) {
    msgs.add(
      'Sztanga ucieka od ciała — myśl o „ściąganiu” po nogach i kontakcie z udami.',
    );
  } else if (maxForward > 0.055) {
    msgs.add('Lekkie wychylenie sztangi od pionu bioder — sprawdź start barków nad gryfem.');
  }

  var directionChanges = 0;
  for (var i = 2; i < relX.length; i++) {
    final x0 = relX[i - 2];
    final x1 = relX[i - 1];
    final x2 = relX[i];
    final a = x1 - x0;
    final b = x2 - x1;
    if (a * b < 0 && b.abs() > 0.012) directionChanges++;
  }
  if (directionChanges >= 5) {
    msgs.add('Tor jest „poszarpany” — uprość ruch (jedna linia nad stopą środkową).');
  }

  if (verticalTravel < 0.06) {
    msgs.add(
      'Słabo widoczny ruch pionowy — ustaw kamerę tak, by widać było całe podejście.',
    );
  }

  if (msgs.isEmpty) {
    msgs.add(
      'Tor wygląda relatywnie zbliżony i kontrolowany — kontynuuj pracę nad stałym kontaktem z nogami.',
    );
  }
  return msgs;
}

BarbellTechniqueMetrics buildTechniqueMetrics(List<BarbellSample> samples) {
  if (samples.length < 2) return BarbellTechniqueMetrics.empty;
  final centerX = samples.map((s) => s.hipMidX).reduce((a, b) => a + b) / samples.length;
  final meanDeviation =
      samples.map((s) => (s.barX - centerX).abs()).reduce((a, b) => a + b) / samples.length;
  final maxHorizontalDeviation =
      samples.map((s) => (s.barX - centerX).abs()).reduce((a, b) => a > b ? a : b);
  var trajectoryLength = 0.0;
  var maxVerticalSpeed = 0.0;
  for (var i = 1; i < samples.length; i++) {
    final a = samples[i - 1];
    final b = samples[i];
    final dx = b.barX - a.barX;
    final dy = b.barY - a.barY;
    trajectoryLength += math.sqrt(dx * dx + dy * dy);
    final dt = (b.t - a.t).clamp(0.001, double.infinity);
    final vY = (b.barY - a.barY).abs() / dt;
    if (vY > maxVerticalSpeed) maxVerticalSpeed = vY;
  }
  final stabilityScore =
      (100 - _std(samples.map((s) => s.barX).toList()) * 1400).clamp(0.0, 100.0);
  return BarbellTechniqueMetrics(
    meanDeviation: double.parse(meanDeviation.toStringAsFixed(4)),
    trajectoryLength: double.parse(trajectoryLength.toStringAsFixed(4)),
    stabilityScore: double.parse(stabilityScore.toStringAsFixed(1)),
    maxVerticalSpeed: double.parse(maxVerticalSpeed.toStringAsFixed(4)),
    maxHorizontalDeviation: double.parse(maxHorizontalDeviation.toStringAsFixed(4)),
  );
}
