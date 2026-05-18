import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Karta wyniku do eksportu PNG (idea #117).
class ResultShareCard extends StatelessWidget {
  const ResultShareCard({
    super.key,
    required this.athleteName,
    required this.title,
    required this.detail,
    required this.dateLabel,
  });

  final String athleteName;
  final String title;
  final String detail;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D9488);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CKS Slavia',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            athleteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dateLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'slavia.cksw.pl',
            style: TextStyle(color: primary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class ResultShareService {
  ResultShareService._();
  static final ResultShareService instance = ResultShareService._();

  Future<void> shareResultCard({
    required BuildContext context,
    required String athleteName,
    required String title,
    required String detail,
    required String dateLabel,
  }) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -1000,
        top: -1000,
        child: RepaintBoundary(
          key: key,
          child: ResultShareCard(
            athleteName: athleteName,
            title: title,
            detail: detail,
            dateLabel: dateLabel,
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Nie udało się wygenerować grafiki');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Pusty obraz PNG');
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/slavia_wynik_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: '$title — $detail',
          subject: 'Wynik — CKS Slavia',
        ),
      );
    } finally {
      entry.remove();
    }
  }
}
