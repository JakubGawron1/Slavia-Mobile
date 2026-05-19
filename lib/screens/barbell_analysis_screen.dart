import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../config/app_brand.dart';
import '../main.dart';
import '../services/barbell_premium_service.dart';
import '../services/barbell_session_store.dart';
import '../services/barbell_video_analyzer.dart';
import '../ui/slavia_ui.dart';
import '../utils/barbell_path_analysis.dart';
import '../widgets/barbell_path_chart.dart';

/// Analiza toru sztangi — Premium offline (ML Kit) + fallback WWW (MoveNet).
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
  bool _analyzing = false;
  String? _analysisError;
  List<BarbellSample> _samples = const [];
  BarbellAnalysisResult? _lastResult;
  List<BarbellSessionRecord> _history = const [];
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarbellPremiumService>().load();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await BarbellSessionStore.instance.list();
    if (!mounted) return;
    setState(() => _history = list);
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
      _samples = const [];
      _lastResult = null;
      _analysisError = null;
    });
  }

  Future<void> _openWebAnalysis() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _openingWeb = true);
    final ok = await AppBrand.openBarbellAnalysis(auth.user?.roles ?? []);
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

  Future<void> _runOfflineAnalysis() async {
    final premium = context.read<BarbellPremiumService>();
    final auth = context.read<AuthProvider>();
    if (!premium.isPremiumFor(auth.user)) {
      _showPremiumSheet();
      return;
    }
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Najpierw wybierz nagranie.')),
      );
      return;
    }

    setState(() {
      _analyzing = true;
      _analysisError = null;
    });

    try {
      final result = await BarbellVideoAnalyzer.analyzeFile(_videoFile!.path);
      if (!mounted) return;
      if (!result.ok) {
        setState(() {
          _analyzing = false;
          _analysisError = result.warning;
          _samples = const [];
          _lastResult = result;
        });
        return;
      }

      final metrics = buildTechniqueMetrics(result.samples);
      final session = BarbellSessionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        videoName: _videoFile!.name,
        samples: result.samples,
        stabilityScore: metrics.stabilityScore,
        trajectoryLength: metrics.trajectoryLength,
        framesWithPose: result.framesWithPose,
      );
      await BarbellSessionStore.instance.save(session);
      await _loadHistory();

      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _samples = result.samples;
        _lastResult = result;
        _activeSessionId = session.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _analysisError = e.toString();
      });
    }
  }

  void _showPremiumSheet() {
    final premium = context.read<BarbellPremiumService>();
    final auth = context.read<AuthProvider>();
    final isAthlete = auth.user?.roles.contains('Athlete') ?? false;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Slavia Premium — analiza offline',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Analiza toru sztangi w aplikacji działa bez internetu — '
              'obliczenia na urządzeniu, wideo nie opuszcza telefonu.',
              style: GoogleFonts.outfit(height: 1.4),
            ),
            const SizedBox(height: 16),
            if (isAthlete) ...[
              FilledButton.icon(
                onPressed: () async {
                  await premium.unlockAthleteBeta();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium odblokowane (beta klubowa).'),
                    ),
                  );
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Odblokuj Premium (beta)'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openWebAnalysis();
              },
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text('Użyj darmowej analizy w przeglądarce'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadSession(BarbellSessionRecord session) {
    setState(() {
      _samples = session.samples;
      _activeSessionId = session.id;
      _lastResult = BarbellAnalysisResult(
        samples: session.samples,
        framesAnalyzed: session.framesWithPose,
        framesWithPose: session.framesWithPose,
      );
      _analysisError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final premium = context.watch<BarbellPremiumService>();
    final auth = context.watch<AuthProvider>();
    final hasPremium = premium.isPremiumFor(auth.user);
    final displaySamples = _samples.isNotEmpty ? _samples : const <BarbellSample>[];
    final metrics = displaySamples.isNotEmpty
        ? buildTechniqueMetrics(displaySamples)
        : BarbellTechniqueMetrics.empty;
    final feedback = displaySamples.isNotEmpty
        ? buildBiomechanicalFeedback(displaySamples)
        : const <String>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Analiza sztangi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (hasPremium)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(Icons.workspace_premium_rounded, size: 18, color: cs.primary),
                label: Text(
                  'Premium',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
        ],
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
            hasPremium
                ? 'Premium: analiza offline na urządzeniu (ML Kit). '
                    'Wideo nie trafia na serwer. Historia zapisuje się lokalnie.'
                : 'Odblokuj Premium, aby analizować offline w aplikacji, '
                    'lub użyj darmowej analizy w przeglądarce.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          _buildVideoCard(context, primary),
          const SizedBox(height: 16),
          _buildAnalysisCard(context, cs, hasPremium),
          if (_analysisError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
                color: cs.errorContainer.withValues(alpha: 0.35),
              ),
              child: Text(
                _analysisError!,
                style: GoogleFonts.outfit(color: cs.error, height: 1.35),
              ),
            ),
          ],
          if (displaySamples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildResultsCard(context, cs, displaySamples, metrics, feedback),
          ],
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHistoryCard(context, cs),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Color primary) {
    return Container(
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  onPressed: _analyzing ? null : () => _pickVideo(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SlaviaUi.primaryButton(
                  context,
                  label: 'Kamera',
                  icon: Icons.videocam_rounded,
                  onPressed: _analyzing ? null : () => _pickVideo(ImageSource.camera),
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, ColorScheme cs, bool hasPremium) {
    return Container(
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
            label: _analyzing
                ? 'Analizuję…'
                : (hasPremium ? 'Analizuj offline (Premium)' : 'Analizuj offline — Premium'),
            icon: hasPremium ? Icons.offline_bolt_rounded : Icons.workspace_premium_rounded,
            onPressed: _analyzing ? null : _runOfflineAnalysis,
          ),
          if (_analyzing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Detekcja pozy na urządzeniu — to może potrwać kilkanaście sekund.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SlaviaUi.primaryButton(
            context,
            label: _openingWeb ? 'Otwieranie…' : 'Analizuj w przeglądarce (darmowe)',
            icon: Icons.open_in_browser_rounded,
            onPressed: (_openingWeb || _analyzing) ? null : _openWebAnalysis,
            filled: false,
          ),
          if (_lastResult != null && _lastResult!.ok) ...[
            const SizedBox(height: 8),
            Text(
              'Wykryto pozę w ${_lastResult!.framesWithPose}/${_lastResult!.framesAnalyzed} klatkach.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsCard(
    BuildContext context,
    ColorScheme cs,
    List<BarbellSample> samples,
    BarbellTechniqueMetrics metrics,
    List<String> feedback,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SlaviaUi.cardShell(context, borderTint: cs.tertiary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlaviaUi.sectionHeader(
            context,
            'Twój tor',
            accent: cs.tertiary,
            icon: Icons.show_chart_rounded,
          ),
          BarbellPathChart(samples: samples),
          const SizedBox(height: 14),
          _MetricsGrid(metrics: metrics),
          const SizedBox(height: 12),
          ...feedback.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 18, color: cs.primary),
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
    );
  }

  Widget _buildHistoryCard(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SlaviaUi.cardShell(context, borderTint: cs.outline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlaviaUi.sectionHeader(
            context,
            'Historia offline',
            accent: cs.outline,
            icon: Icons.history_rounded,
          ),
          ..._history.take(8).map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                s.videoName,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${s.createdAt.toLocal().toString().substring(0, 16)} · '
                'stabilność ${s.stabilityScore.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  await BarbellSessionStore.instance.delete(s.id);
                  await _loadHistory();
                  if (!mounted) return;
                  if (_activeSessionId == s.id) {
                    setState(() {
                      _samples = const [];
                      _lastResult = null;
                      _activeSessionId = null;
                    });
                  }
                },
              ),
              onTap: () => _loadSession(s),
            ),
          ),
        ],
      ),
    );
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
