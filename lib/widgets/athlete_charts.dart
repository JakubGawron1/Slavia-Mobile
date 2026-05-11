import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/athlete_analytics.dart';

/// Wykres liniowy progresu dwuboju (zawody) — odpowiednik `AthleteProgressChart.vue`.
class TotalProgressChart extends StatefulWidget {
  final List<AthleteChartPoint> series;
  final double height;

  const TotalProgressChart({
    super.key,
    required this.series,
    this.height = 200,
  });

  @override
  State<TotalProgressChart> createState() => _TotalProgressChartState();
}

class _TotalProgressChartState extends State<TotalProgressChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    if (widget.series.length < 2) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final s = widget.series;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progres dwuboju (zawody)',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, cons) {
            final w = cons.maxWidth;
            final h = widget.height;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (e) =>
                  _setHover(e.localPosition.dx, w, s.length),
              onHorizontalDragStart: (e) =>
                  _setHover(e.localPosition.dx, w, s.length),
              onHorizontalDragEnd: (_) => setState(() => _hover = null),
              onTapDown: (e) => _setHover(e.localPosition.dx, w, s.length),
              onTapUp: (_) => setState(() => _hover = null),
              child: CustomPaint(
                size: Size(w, h),
                painter: _TotalProgressPainter(
                  series: s,
                  primary: cs.primary,
                  hoverIndex: _hover,
                ),
              ),
            );
          },
        ),
        if (_hover != null && _hover! >= 0 && _hover! < s.length) ...[
          const SizedBox(height: 8),
          Text(
            '${s[_hover!].date} · ${s[_hover!].total.toStringAsFixed(0)} kg · rwanie ${s[_hover!].snatch.toStringAsFixed(0)} · podrzut ${s[_hover!].cleanAndJerk.toStringAsFixed(0)}'
            '${s[_hover!].sinclair != null ? ' · Sinclair ${s[_hover!].sinclair}' : ''}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }

  void _setHover(double dx, double width, int n) {
    const padL = 8.0;
    const padR = 8.0;
    final plotW = width - padL - padR;
    if (plotW <= 0 || n < 2) return;
    final t = ((dx - padL) / plotW * (n - 1)).round().clamp(0, n - 1);
    setState(() => _hover = t);
  }
}

class _TotalProgressPainter extends CustomPainter {
  final List<AthleteChartPoint> series;
  final Color primary;
  final int? hoverIndex;

  _TotalProgressPainter({
    required this.series,
    required this.primary,
    this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = series.length;
    if (n < 2) return;
    const padL = 8.0;
    const padR = 8.0;
    const padT = 14.0;
    const padB = 22.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final totals = series.map((e) => e.total).toList();
    var minV = totals.reduce(math.min) * 0.94;
    var maxV = totals.reduce(math.max) * 1.06;
    if ((maxV - minV).abs() < 1e-3) {
      minV -= 2;
      maxV += 2;
    }
    final range = maxV - minV;

    Offset pt(int i) {
      final x = padL + (i / (n - 1)) * plotW;
      final y = padT + plotH - ((totals[i] - minV) / range) * plotH;
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < n; i++) {
      linePath.lineTo(pt(i).dx, pt(i).dy);
    }
    final first = pt(0);
    final last = pt(n - 1);
    final areaPath = Path.from(linePath)
      ..lineTo(last.dx, size.height - padB)
      ..lineTo(first.dx, size.height - padB)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, padT),
          Offset(0, size.height - padB),
          [primary.withValues(alpha: 0.32), primary.withValues(alpha: 0.03)],
        ),
    );

    for (var k = 1; k <= 3; k++) {
      final gy = padT + (plotH * k) / 4;
      canvas.drawLine(
        Offset(padL, gy),
        Offset(size.width - padR, gy),
        Paint()
          ..color = primary.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final hi = hoverIndex;
    if (hi != null && hi >= 0 && hi < n) {
      final p = pt(hi);
      canvas.drawCircle(p, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: '${maxV.round()} kg',
        style: TextStyle(fontSize: 10, color: primary.withValues(alpha: 0.55)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(padL, 2));

    final tp2 = TextPainter(
      text: TextSpan(
        text: '${minV.round()} kg',
        style: TextStyle(fontSize: 10, color: primary.withValues(alpha: 0.45)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(padL, padT + plotH - 4));
  }

  @override
  bool shouldRepaint(covariant _TotalProgressPainter oldDelegate) =>
      oldDelegate.hoverIndex != hoverIndex ||
      !identical(oldDelegate.series, series);
}

/// Zawody vs trening na osi czasu — uproszczony odpowiednik `AthleteCombinedChart.vue`.
class CombinedTimelineChart extends StatelessWidget {
  final List<CombinedChartPoint> series;
  final double height;

  const CombinedTimelineChart({
    super.key,
    required this.series,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final valid = series.where((p) => p.total > 0 && p.total.isFinite).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (valid.length < 2) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zawody vs trening (oś czasu)',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _LegendDot(color: cs.primary, label: 'Zawody'),
            const SizedBox(width: 16),
            _LegendDot(color: cs.tertiary, label: 'Trening'),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, cons) {
            return CustomPaint(
              size: Size(cons.maxWidth, height),
              painter: _CombinedPainter(
                series: valid,
                compColor: cs.primary,
                trainColor: cs.tertiary,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CombinedPainter extends CustomPainter {
  final List<CombinedChartPoint> series;
  final Color compColor;
  final Color trainColor;

  _CombinedPainter({
    required this.series,
    required this.compColor,
    required this.trainColor,
  });

  int _ts(String d) {
    final s = d.length >= 10 ? d.substring(0, 10) : d;
    return DateTime.tryParse('${s}T00:00:00')?.millisecondsSinceEpoch ?? 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 10.0;
    const padR = 10.0;
    const padT = 18.0;
    const padB = 24.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final totals = series.map((e) => e.total).toList();
    var minV = totals.reduce(math.min) * 0.92;
    var maxV = totals.reduce(math.max) * 1.06;
    if ((maxV - minV).abs() < 1e-3) {
      minV -= 2;
      maxV += 2;
    }
    final range = maxV - minV;
    final t0 = _ts(series.first.date);
    final t1 = _ts(series.last.date);
    final tSpan = math.max(1, t1 - t0);

    Offset xy(CombinedChartPoint p) {
      final t = _ts(p.date);
      final x = padL + ((t - t0) / tSpan) * plotW;
      final y = padT + plotH - ((p.total - minV) / range) * plotH;
      return Offset(x, y);
    }

    void drawKindPolyline(String kind, Color color) {
      final pts = series.where((p) => p.kind == kind).map(xy).toList();
      if (pts.length < 2) return;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }

    drawKindPolyline('competition', compColor);
    drawKindPolyline('training', trainColor);

    for (final p in series) {
      final o = xy(p);
      final c = p.kind == 'training' ? trainColor : compColor;
      canvas.drawCircle(o, 5, Paint()..color = c);
      canvas.drawCircle(
        o,
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CombinedPainter oldDelegate) =>
      !identical(oldDelegate.series, series);
}
