import 'package:flutter/material.dart';

import '../utils/barbell_path_analysis.dart';

/// Nakładka toru sztangi na odtwarzacz wideo — synchronizacja z `currentTimeSec`.
class BarbellVideoOverlay extends StatelessWidget {
  const BarbellVideoOverlay({
    super.key,
    required this.samples,
    required this.currentTimeSec,
    this.barColor,
  });

  final List<BarbellSample> samples;
  final double currentTimeSec;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();
    final color = barColor ?? Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
            return const SizedBox.expand();
          }
          return CustomPaint(
            size: Size(w, h),
            isComplex: true,
            willChange: true,
            painter: _BarbellVideoOverlayPainter(
              samples: samples,
              currentTimeSec: currentTimeSec,
              barColor: color,
            ),
          );
        },
      ),
    );
  }
}

class _BarbellVideoOverlayPainter extends CustomPainter {
  _BarbellVideoOverlayPainter({
    required this.samples,
    required this.currentTimeSec,
    required this.barColor,
  });

  final List<BarbellSample> samples;
  final double currentTimeSec;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = samples.where((s) => s.t <= currentTimeSec + 0.04).toList();
    if (visible.length < 2) {
      if (visible.length == 1) {
        final p = _map(visible.first, size);
        canvas.drawCircle(p, 6, Paint()..color = barColor);
      }
      return;
    }

    final path = Path();
    for (var i = 0; i < visible.length; i++) {
      final p = _map(visible[i], size);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final glow = Paint()
      ..color = barColor.withValues(alpha: 0.35)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glow);

    final stroke = Paint()
      ..color = barColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    final head = _map(visible.last, size);
    canvas.drawCircle(
      head,
      7,
      Paint()..color = barColor,
    );
    canvas.drawCircle(
      head,
      11,
      Paint()
        ..color = barColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Offset _map(BarbellSample s, Size size) {
    return Offset(s.barX * size.width, s.barY * size.height);
  }

  @override
  bool shouldRepaint(covariant _BarbellVideoOverlayPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        (oldDelegate.currentTimeSec - currentTimeSec).abs() > 0.01 ||
        oldDelegate.barColor != barColor;
  }
}
