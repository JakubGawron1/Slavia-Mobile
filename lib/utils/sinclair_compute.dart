import 'package:flutter/foundation.dart';

import 'sinclair_utils.dart';

class SinclairBatchInput {
  final List<double> totals;
  final List<double> bodyweights;
  final String genderKey;

  const SinclairBatchInput({
    required this.totals,
    required this.bodyweights,
    required this.genderKey,
  });
}

List<double> _sinclairTotalsIsolate(SinclairBatchInput input) {
  final gender = input.genderKey == 'female'
      ? SinclairGender.female
      : SinclairGender.male;
  final out = <double>[];
  final len = input.totals.length;
  for (var i = 0; i < len; i++) {
    final total = i < input.totals.length ? input.totals[i] : 0.0;
    final bw = i < input.bodyweights.length ? input.bodyweights[i] : 0.0;
    out.add(SinclairCalculator.calculateTotal(total, bw, gender));
  }
  return out;
}

/// Przeliczenia Sinclair w isolate — idea #199.
Future<List<double>> computeSinclairTotalsBatch(SinclairBatchInput input) {
  if (input.totals.length < 32) {
    return Future.value(_sinclairTotalsIsolate(input));
  }
  return compute(_sinclairTotalsIsolate, input);
}
