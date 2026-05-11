import 'dart:math' as math;

enum SinclairGender { male, female }

class SinclairConstants {
  final double a;
  final double b;

  const SinclairConstants({required this.a, required this.b});
}

class SinclairCalculator {
  static const Map<SinclairGender, SinclairConstants> constants = {
    SinclairGender.male: SinclairConstants(a: 0.7023570715147177, b: 201),
    SinclairGender.female: SinclairConstants(a: 0.6734030019259942, b: 164),
  };

  static double calculateCoefficient(double bodyweight, SinclairGender gender) {
    if (bodyweight <= 0) return 0.0;
    final c = constants[gender]!;
    if (bodyweight >= c.b) return 1.0;

    final logRatio = math.log(bodyweight / c.b) / math.ln10;
    return math.pow(10, c.a * logRatio * logRatio).toDouble();
  }

  static double calculateTotal(
    double total,
    double bodyweight,
    SinclairGender gender,
  ) {
    if (total <= 0 || bodyweight <= 0) return 0.0;
    return total * calculateCoefficient(bodyweight, gender);
  }
}
