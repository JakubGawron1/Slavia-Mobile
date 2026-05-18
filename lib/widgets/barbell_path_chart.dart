import 'package:flutter/material.dart';

import '../utils/barbell_path_analysis.dart';

/// Rysuje tor sztangi (współrzędne znormalizowane 0–1) na tle siatki.
class BarbellPathChart extends StatelessWidget {
  const BarbellPathChart({
    super.key,
    required this.samples,
    this.hipLine = true,
  });

  final List<BarbellSample> samples;
  final bool hipLine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: CustomPaint(
        painter: _BarbellPathPainter(
          samples: samples,
          barColor: cs.primary,
          hipColor: cs.tertiary,
          gridColor: cs.outline.withValues(alpha: 0.2),
          hipLine: hipLine,
        ),
      ),
    );
  }
}

class _BarbellPathPainter extends CustomPainter {
  _BarbellPathPainter({
    required this.samples,
    required this.barColor,
    required this.hipColor,
    required this.gridColor,
    required this.hipLine,
  });

  final List<BarbellSample> samples;
  final Color barColor;
  final Color hipColor;
  final Color gridColor;
  final bool hipLine;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    if (samples.length < 2) return;

    Offset map(double nx, double ny) {
      return Offset(nx * size.width, ny * size.height);
    }

    if (hipLine) {
      final hipY = samples.map((s) => s.barY).reduce((a, b) => a + b) / samples.length;
      final hipPaint = Paint()
        ..color = hipColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, map(0, hipY).dy),
        Offset(size.width, map(1, hipY).dy),
        hipPaint,
      );
    }

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final p = map(samples[i].barX, samples[i].barY);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final barPaint = Paint()
      ..color = barColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, barPaint);

    final dot = samples.last;
    canvas.drawCircle(
      map(dot.barX, dot.barY),
      5,
      Paint()..color = barColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BarbellPathPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}
