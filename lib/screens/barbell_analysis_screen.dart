import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../config/app_brand.dart';
import '../main.dart';
import '../ui/slavia_ui.dart';
import '../utils/barbell_path_analysis.dart';
import '../widgets/barbell_path_chart.dart';

/// Analiza toru sztangi — MVP: wybór wideo + pełna analiza w przeglądarce (MoveNet na WWW).
/// TODO: on-device pose detection (TFLite / ML Kit) i lokalne liczenie toru.
class BarbellAnalysisScreen extends StatefulWidget {
  const BarbellAnalysisScreen({super.key});

  @override
  State<BarbellAnalysisScreen> createState() => _BarbellAnalysisScreenState();
}

class _BarbellAnalysisScreenState extends State<BarbellAnalysisScreen> {
  final _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  bool _openingWeb = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 45),
    );
    if (file == null || !mounted) return;
    await _videoController?.dispose();
    final controller = VideoPlayerController.file(File(file.path));
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _videoFile = file;
      _videoController = controller..setLooping(true)..play();
    });
  }

  Future<void> _openWebAnalysis() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roles = auth.user?.roles ?? [];
    setState(() => _openingWeb = true);
    final ok = await AppBrand.openBarbellAnalysis(roles);
    if (!mounted) return;
    setState(() => _openingWeb = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nie udało się otworzyć analizy w przeglądarce.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final demoSamples = _demoSamplesForPreview();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Analiza sztangi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SlaviaUi.homeBadge(context, 'TOR SZTANGI'),
          const SizedBox(height: 12),
          Text(
            'Nagraj podejście z profilu',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pełna analiza toru i wskazówki techniczne działają w przeglądarce '
            '(obliczenia na urządzeniu — wideo nie trafia na serwer). '
            'W aplikacji możesz wybrać nagranie i przejść do analizy jednym kliknięciem.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SlaviaUi.cardShell(context, borderTint: primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SlaviaUi.sectionHeader(
                  context,
                  'Krok 1 — nagranie',
                  accent: primary,
                  icon: Icons.videocam_outlined,
                ),
                if (_videoController != null && _videoController!.value.isInitialized) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _videoFile?.name ?? 'Wybrane wideo',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ] else
                  SlaviaUi.emptyState(
                    context,
                    icon: Icons.fitness_center_rounded,
                    title: 'Brak nagrania',
                    subtitle: 'Wybierz krótki klip (5–20 s) z profilu, dobre światło, cała sylwetka.',
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SlaviaUi.primaryButton(
                        context,
                        label: 'Galeria',
                        icon: Icons.photo_library_outlined,
                        onPressed: () => _pickVideo(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SlaviaUi.primaryButton(
                        context,
                        label: 'Kamera',
                        icon: Icons.videocam_rounded,
                        onPressed: () => _pickVideo(ImageSource.camera),
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SlaviaUi.cardShell(context, borderTint: cs.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SlaviaUi.sectionHeader(
                  context,
                  'Krok 2 — analiza',
                  accent: cs.secondary,
                  icon: Icons.auto_graph_rounded,
                ),
                SlaviaUi.primaryButton(
                  context,
                  label: _openingWeb ? 'Otwieranie…' : 'Analizuj w przeglądarce',
                  icon: Icons.open_in_browser_rounded,
                  onPressed: _openingWeb ? null : _openWebAnalysis,
                ),
                const SizedBox(height: 10),
                Text(
                  'Wymaga włączonej funkcji barbell_pose_analysis na stronie klubu. '
                  'Zaloguj się tym samym kontem co w aplikacji.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SlaviaUi.cardShell(context, borderTint: cs.tertiary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlaviaUi.sectionHeader(
                  context,
                  'Podgląd wykresu (przykład)',
                  accent: cs.tertiary,
                  icon: Icons.show_chart_rounded,
                ),
                Text(
                  'Po wdrożeniu detekcji pozy w aplikacji zobaczysz tu swój tor. '
                  'Poniżej przykładowy kształt i metryki.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                BarbellPathChart(samples: demoSamples),
                const SizedBox(height: 14),
                _MetricsGrid(metrics: buildTechniqueMetrics(demoSamples)),
                const SizedBox(height: 12),
                ...buildBiomechanicalFeedback(demoSamples).map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_outlined, size: 18, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m,
                            style: GoogleFonts.outfit(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.construction_rounded, size: 20, color: cs.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Planowane: analiza w aplikacji (MoveNet / ML Kit), zapis historii, porównanie A/B.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.4,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Syntetyczny tor do podglądu UI — zastąpi detekcja z wideo.
  List<BarbellSample> _demoSamplesForPreview() {
    const n = 24;
    return List.generate(n, (i) {
      final t = i / (n - 1) * 2.4;
      final phase = i / n;
      final barX = 0.48 + 0.06 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
      final barY = 0.72 - 0.38 * phase + 0.02 * (phase - 0.5) * (phase - 0.5);
      return BarbellSample(
        t: t,
        barX: barX,
        barY: barY,
        hipMidX: 0.5,
        shoulderMidX: 0.52,
      );
    });
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final BarbellTechniqueMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SlaviaUi.radiusSm),
            color: cs.primary.withValues(alpha: 0.06),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            cell('Stabilność', '${metrics.stabilityScore.toStringAsFixed(0)}%'),
            const SizedBox(width: 8),
            cell('Długość toru', metrics.trajectoryLength.toStringAsFixed(2)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            cell('Odchylenie', metrics.meanDeviation.toStringAsFixed(3)),
            const SizedBox(width: 8),
            cell('Max bok', metrics.maxHorizontalDeviation.toStringAsFixed(3)),
          ],
        ),
      ],
    );
  }
}
