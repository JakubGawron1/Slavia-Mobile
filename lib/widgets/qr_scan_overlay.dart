import 'package:flutter/material.dart';

/// Ramka skanera QR z przyciemnionym tłem i animowaną linią skanowania.
class QrScanOverlay extends StatefulWidget {
  const QrScanOverlay({
    super.key,
    this.frameSize = 260,
    this.hint,
  });

  final double frameSize;
  final String? hint;

  @override
  State<QrScanOverlay> createState() => _QrScanOverlayState();
}

class _QrScanOverlayState extends State<QrScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final frame = widget.frameSize.clamp(180.0, size.shortestSide * 0.72);
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.46),
          width: frame,
          height: frame,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _QrDimPainter(cutout: rect, radius: 18),
            ),
            CustomPaint(
              painter: _QrFramePainter(
                rect: rect,
                color: accent,
                radius: 18,
              ),
            ),
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, _) {
                final y = rect.top + 12 + (rect.height - 24) * _scanCtrl.value;
                return CustomPaint(
                  painter: _QrScanLinePainter(
                    rect: rect,
                    y: y,
                    color: accent,
                  ),
                );
              },
            ),
            Positioned(
              left: 24,
              right: 24,
              top: rect.bottom + 20,
              child: Text(
                widget.hint ??
                    'Umieść kod QR w ramce. Skanowanie rozpocznie się automatycznie.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QrDimPainter extends CustomPainter {
  _QrDimPainter({required this.cutout, required this.radius});

  final Rect cutout;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout, Radius.circular(radius)));
    final dim = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(
      dim,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _QrDimPainter oldDelegate) =>
      oldDelegate.cutout != cutout;
}

class _QrFramePainter extends CustomPainter {
  _QrFramePainter({
    required this.rect,
    required this.color,
    required this.radius,
  });

  final Rect rect;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      border,
    );

    const arm = 28.0;
    const thick = 4.0;
    final p = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, p);
      canvas.drawLine(start, vEnd, p);
    }

    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    corner(tl, tl + Offset(arm, 0), tl + Offset(0, arm));
    corner(tr, tr + Offset(-arm, 0), tr + Offset(0, arm));
    corner(bl, bl + Offset(arm, 0), bl + Offset(0, -arm));
    corner(br, br + Offset(-arm, 0), br + Offset(0, -arm));
  }

  @override
  bool shouldRepaint(covariant _QrFramePainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.color != color;
}

class _QrScanLinePainter extends CustomPainter {
  _QrScanLinePainter({
    required this.rect,
    required this.y,
    required this.color,
  });

  final Rect rect;
  final double y;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lineRect = Rect.fromLTWH(
      rect.left + 14,
      y,
      rect.width - 28,
      2,
    );
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0),
        ],
      ).createShader(lineRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      gradient,
    );
  }

  @override
  bool shouldRepaint(covariant _QrScanLinePainter oldDelegate) =>
      oldDelegate.y != y || oldDelegate.color != color;
}
