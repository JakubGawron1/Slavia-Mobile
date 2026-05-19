import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/slavia_ui.dart';
import '../utils/parse_live_number.dart';
import '../utils/weightlifting_ratios.dart';

/// Kalkulator „złotych proporcji” — funkcjonalnie jak `/kalkulator-proporcji` na WWW.
class ProportionsCalculatorPage extends StatefulWidget {
  const ProportionsCalculatorPage({super.key});

  @override
  State<ProportionsCalculatorPage> createState() =>
      _ProportionsCalculatorPageState();
}

class _ProportionsCalculatorPageState extends State<ProportionsCalculatorPage> {
  late final Map<ExerciseId, TextEditingController> _controllers;
  String _query = '';
  bool _showOnlyOutOfRange = false;
  bool _showOnlyComputed = true;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final id in ExerciseId.values) id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<ExerciseId, double?> _parseInputs() {
    final out = <ExerciseId, double?>{};
    for (final e in _controllers.entries) {
      final parsed = parseLiveNumber(e.value.text);
      if (parsed == null) {
        out[e.key] = null;
        continue;
      }
      if (parsed > 0) {
        out[e.key] = parsed;
      } else {
        out[e.key] = null;
      }
    }
    return out;
  }

  int _filledCount(Map<ExerciseId, double?> inputs) {
    var n = 0;
    for (final v in inputs.values) {
      if (v != null && v.isFinite && v > 0) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final inputs = _parseInputs();
    final results = WeightliftingRatios.computeRatios(inputs);
    final filled = _filledCount(inputs);

    final summary = _ResultSummary.from(results);
    final filtered = results.where((r) {
      if (_showOnlyComputed && (r.minKg == null || r.maxKg == null)) {
        return false;
      }
      if (_showOnlyOutOfRange && r.status != 'below' && r.status != 'above') {
        return false;
      }
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay = '${r.pl} ${r.fromPl}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    final relationAnalyses = results
        .where((r) => r.actualPct != null)
        .toList()
      ..sort((a, b) {
        int rank(String s) {
          if (s == 'below') return 0;
          if (s == 'above') return 1;
          if (s == 'in_range') return 2;
          return 3;
        }

        final ra = rank(a.status);
        final rb = rank(b.status);
        if (ra != rb) return ra.compareTo(rb);
        return '${a.pl} ${a.fromPl}'
            .toLowerCase()
            .compareTo('${b.pl} ${b.fromPl}'.toLowerCase());
      });

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            title: Text(
              'Złote proporcje',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SlaviaUi.radiusXl),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withValues(alpha: isDark ? 0.22 : 0.14),
                          cs.surface,
                          cs.surface,
                        ],
                      ),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.28 : 0.06),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SlaviaUi.homeBadge(context, 'Narzędzie'),
                        const SizedBox(height: 10),
                        Text(
                          'Widełki między bojami',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wpisz znane maxy (1RM). Dostaniesz sugerowane widełki oraz wskazówki, gdy podasz oba boje w relacji — tak samo jak w kalkulatorze na stronie klubu.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.45,
                            color: cs.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _primaryInputsRow(context),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text(
                      'Wszystkie maxy (1RM)',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '$filled wypełnionych pól',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    children: [
                      for (var i = 0;
                          i < WeightliftingRatios.allInputKeys.length;
                          i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _field(
                                  WeightliftingRatios.allInputKeys[i],
                                ),
                              ),
                              if (i + 1 <
                                  WeightliftingRatios.allInputKeys.length) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _field(
                                    WeightliftingRatios.allInputKeys[i + 1],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SlaviaUi.sectionHeader(
                    context,
                    'Filtry i podsumowanie',
                    accent: cs.secondary,
                    icon: Icons.tune_rounded,
                  ),
                  _SummaryChips(summary: summary, filled: filled),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Szukaj po nazwie ćwiczenia…',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tylko z policzonym zakresem'),
                        selected: _showOnlyComputed,
                        onSelected: (v) =>
                            setState(() => _showOnlyComputed = v),
                      ),
                      FilterChip(
                        label: const Text('Tylko poza widełkami'),
                        selected: _showOnlyOutOfRange,
                        onSelected: (v) =>
                            setState(() => _showOnlyOutOfRange = v),
                      ),
                    ],
                  ),
                  if (relationAnalyses.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    SlaviaUi.sectionHeader(
                      context,
                      'Analiza relacji (oba boje wpisane)',
                      accent: cs.tertiary,
                      icon: Icons.insights_rounded,
                    ),
                    ...relationAnalyses.map(_relationTile),
                  ],
                  const SizedBox(height: 16),
                  SlaviaUi.sectionHeader(
                    context,
                    'Wyniki (${filtered.length})',
                    accent: cs.primary,
                    icon: Icons.table_rows_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Brak wierszy przy obecnych filtrach. Wpisz max bazowy lub zmień filtry.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _resultCard(filtered[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryInputsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SlaviaUi.cardShell(context, borderTint: cs.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kluczowe boje',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(ExerciseId.snatch)),
              const SizedBox(width: 10),
              Expanded(child: _field(ExerciseId.cleanJerk)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(ExerciseId.backSquat)),
              const SizedBox(width: 10),
              Expanded(child: _field(ExerciseId.frontSquat)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(ExerciseId id) {
    return TextField(
      controller: _controllers[id],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: WeightliftingRatios.labelFor(id),
        suffixText: 'kg',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SlaviaUi.radiusSm),
        ),
      ),
    );
  }

  Widget _relationTile(RatioResult r) {
    final cs = Theme.of(context).colorScheme;
    final c = _statusColor(r.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${r.pl} ← ${r.fromPl}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
              ),
              _statusChip(r.status),
            ],
          ),
          if (r.note != null) ...[
            const SizedBox(height: 8),
            Text(
              r.note!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.45,
                color: cs.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(RatioResult r) {
    final cs = Theme.of(context).colorScheme;
    final accent = _statusColor(r.status);
    final pctLabel = _fmtPctRange(r.ratio);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
        onTap: r.note != null
            ? () {
                HapticFeedback.lightImpact();
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.pl,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Baza: ${r.fromPl} · Widełki ratio: $pctLabel',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (r.note != null)
                          Text(
                            r.note!,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.pl,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Od: ${r.fromPl}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(r.status),
                ],
              ),
              const SizedBox(height: 10),
              if (r.minKg != null && r.maxKg != null)
                Text(
                  'Sugerowane: ${_fmtKgRange(r.minKg, r.maxKg)} · Ratio $pctLabel',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                )
              else
                Text(
                  'Podaj max „${r.fromPl}”, że policzyć zakres.',
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              if (r.actualKg != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Twój zapis: ${r.actualKg!.toStringAsFixed(1)} kg'
                  '${r.actualPct != null ? ' (${r.actualPct!.toStringAsFixed(1)}% bazy)' : ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                r.ratio.source,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              if (r.ratio.heuristic)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Widełki orientacyjne (duża zmienność indywidualna)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: cs.tertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Jak `fmtPct` na WWW — gdy min==max po zaokrągleniu, jedna liczba procentowa.
  String _fmtPctRange(RatioRange r) {
    final a = (r.min * 100).round();
    final b = (r.max * 100).round();
    final lo = a <= b ? a : b;
    final hi = a <= b ? b : a;
    return lo == hi ? '$lo%' : '$lo–$hi%';
  }

  String? _fmtKgRange(double? minKg, double? maxKg) {
    if (minKg == null || maxKg == null) return null;
    final lo = minKg <= maxKg ? minKg : maxKg;
    final hi = minKg <= maxKg ? maxKg : minKg;
    return '${lo.toStringAsFixed(1)}–${hi.toStringAsFixed(1)} kg';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_range':
        return Colors.green.shade600;
      case 'below':
        return Colors.orange.shade700;
      case 'above':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String status) {
    final label = switch (status) {
      'in_range' => 'W normie',
      'below' => 'Poniżej',
      'above' => 'Powyżej',
      _ => '—',
    };
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: c,
        ),
      ),
    );
  }
}

class _ResultSummary {
  final int total;
  final int computed;
  final int withStatus;
  final int inRange;
  final int below;
  final int above;

  _ResultSummary({
    required this.total,
    required this.computed,
    required this.withStatus,
    required this.inRange,
    required this.below,
    required this.above,
  });

  factory _ResultSummary.from(List<RatioResult> rows) {
    final computed =
        rows.where((r) => r.minKg != null && r.maxKg != null).length;
    final withStatus = rows.where((r) => r.status != 'unknown').length;
    return _ResultSummary(
      total: rows.length,
      computed: computed,
      withStatus: withStatus,
      inRange: rows.where((r) => r.status == 'in_range').length,
      below: rows.where((r) => r.status == 'below').length,
      above: rows.where((r) => r.status == 'above').length,
    );
  }
}

class _SummaryChips extends StatelessWidget {
  final _ResultSummary summary;
  final int filled;

  const _SummaryChips({required this.summary, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, 'Relacje: ${summary.total}'),
        _chip(context, 'Z zakresem: ${summary.computed}'),
        _chip(context, 'Z oceną: ${summary.withStatus}'),
        _chip(context, 'OK: ${summary.inRange}'),
        _chip(context, 'Nisko: ${summary.below}'),
        _chip(context, 'Wysoko: ${summary.above}'),
        _chip(context, 'Maxy: $filled'),
      ],
    );
  }

  Widget _chip(BuildContext context, String text) {
    return Chip(
      label: Text(text, style: GoogleFonts.outfit(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
