import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slavia_mobile/utils/sinclair.dart';

void main() {
  test('sinclair vectors match backend embed', () {
    final path = 'test/fixtures/sinclair-test-vectors.json';
    final raw = File(path).readAsStringSync();
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final cases = doc['cases'] as List<dynamic>;

    for (final item in cases) {
      final c = item as Map<String, dynamic>;
      final gender = c['gender'] == 'female' ? SinclairGender.female : SinclairGender.male;
      final bw = (c['bodyweight'] as num).toDouble();
      final total = (c['total'] as num).toDouble();

      if (c.containsKey('expectedCoefficient')) {
        final coef = SinclairCalculator.calculateCoefficient(bw, gender);
        if (c['expectedCoefficient'] == null) {
          expect(coef.isNaN, isTrue);
        } else {
          expect(coef, closeTo((c['expectedCoefficient'] as num).toDouble(), 0.00001));
        }
      }

      if (c.containsKey('expectedTotal')) {
        final result = SinclairCalculator.calculateTotal(total, bw, gender);
        if (c['expectedTotal'] == null) {
          expect(result.isNaN, isTrue);
        } else {
          expect(result, closeTo((c['expectedTotal'] as num).toDouble(), 0.00001));
        }
      }
    }
  });
}
