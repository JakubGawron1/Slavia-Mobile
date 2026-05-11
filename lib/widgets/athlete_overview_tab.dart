import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/athlete.dart';
import '../models/auth.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/athlete_analytics.dart';
import 'athlete_charts.dart';

class AthleteOverviewTab extends StatefulWidget {
  final String athleteId;
  final ApiService api;
  final bool canViewTraining;

  const AthleteOverviewTab({
    super.key,
    required this.athleteId,
    required this.api,
    required this.canViewTraining,
  });

  @override
  State<AthleteOverviewTab> createState() => _AthleteOverviewTabState();
}

class _OverviewBundle {
  final Athlete athlete;
  final List<AthleteChartPoint> progress;
  final List<CombinedChartPoint> combined;
  final AthleteAnalyticsStats stats;
  final PublicStartStats publicStats;
  final ({double? snatch, double? cleanJerk, double? total}) pb;

  _OverviewBundle({
    required this.athlete,
    required this.progress,
    required this.combined,
    required this.stats,
    required this.publicStats,
    required this.pb,
  });
}

class _AthleteOverviewTabState extends State<AthleteOverviewTab> {
  late Future<_OverviewBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<_OverviewBundle> _load() async {
    final athlete = await widget.api.getAthlete(widget.athleteId);
    final compRaw = await widget.api.getAthleteResultHistory(widget.athleteId);
    List<CompetitionResult> trainRaw = [];
    if (widget.canViewTraining) {
      try {
        trainRaw = await widget.api.getAthleteResultHistory(
          widget.athleteId,
          kind: 'training',
        );
      } catch (_) {
        trainRaw = [];
      }
    }
    final comp = approvedCompetitionResults(compRaw);
    final train = approvedTrainingResults(trainRaw);
    final progress = buildProgressSeries(athlete, comp);
    final combined = buildCombinedSeries(
      athlete,
      comp,
      train,
      widget.canViewTraining,
    );
    final stats = computeAthleteAnalyticsStats(athlete, comp, train, combined);
    final publicStats = computePublicStartStats(comp);
    final pb = competitionPbDisplay(athlete, comp);
    return _OverviewBundle(
      athlete: athlete,
      progress: progress,
      combined: combined,
      stats: stats,
      publicStats: publicStats,
      pb: pb,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FutureBuilder<_OverviewBundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nie udało się wczytać danych',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snap.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Odśwież'),
                  ),
                ],
              ),
            ),
          );
        }
        final b = snap.data!;
        final a = b.athlete;

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights_outlined, size: 20, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Statystyki i wykresy zsynchronizowane z profilem na stronie klubu.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SlaviaUi.sectionHeader(
                context,
                'Najlepsze wyniki (PB z zawodów)',
                accent: primary,
                icon: Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'Rwanie',
                      value: b.pb.snatch != null
                          ? '${b.pb.snatch!.toStringAsFixed(0)} kg'
                          : '—',
                      icon: Icons.bolt,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      label: 'Podrzut',
                      value: b.pb.cleanJerk != null
                          ? '${b.pb.cleanJerk!.toStringAsFixed(0)} kg'
                          : '—',
                      icon: Icons.flash_on,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      label: 'Dwubój',
                      value: b.pb.total != null
                          ? '${b.pb.total!.toStringAsFixed(0)} kg'
                          : '—',
                      icon: Icons.emoji_events,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              if (b.stats.bestSinclairCompetition != null) ...[
                const SizedBox(height: 12),
                _SinclairStrip(
                  value: b.stats.bestSinclairCompetition!,
                  primary: primary,
                ),
              ],
              const SizedBox(height: 20),
              SlaviaUi.sectionHeader(
                context,
                'Starty z zawodów',
                accent: primary,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 8),
              _PublicStatsRow(stats: b.publicStats, primary: primary),
              const SizedBox(height: 20),
              if (b.progress.length >= 2) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: SlaviaUi.cardShell(context, borderTint: primary),
                  child: TotalProgressChart(series: b.progress, height: 200),
                ),
                const SizedBox(height: 16),
              ] else if (b.progress.length == 1) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: SlaviaUi.cardShell(context, borderTint: primary),
                  child: _SinglePointCard(p: b.progress.first),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.canViewTraining && b.combined.length >= 2) ...[
                SlaviaUi.sectionHeader(
                  context,
                  'Analityka trening + zawody',
                  accent: Theme.of(context).colorScheme.tertiary,
                  icon: Icons.merge_type_rounded,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: SlaviaUi.cardShell(
                    context,
                    borderTint: Theme.of(context).colorScheme.tertiary,
                  ),
                  child: CombinedTimelineChart(series: b.combined, height: 220),
                ),
                const SizedBox(height: 16),
                _InsightsGrid(
                  stats: b.stats,
                  primary: primary,
                  tertiary: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
              ],
              if (a.bio != null && a.bio!.trim().isNotEmpty) ...[
                SlaviaUi.sectionHeader(
                  context,
                  'O mnie',
                  accent: primary,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: SlaviaUi.cardShell(context),
                  child: Text(
                    a.bio!.trim(),
                    style: GoogleFonts.outfit(fontSize: 14, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SlaviaUi.sectionHeader(
                context,
                'Dane zawodnika',
                accent: primary,
                icon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 8),
              _InfoTable(
                rows: [
                  if (a.birthYear != null)
                    _InfoRow('Rocznik', '${a.birthYear}'),
                  if (a.weightCategory != null)
                    _InfoRow('Kategoria wagowa', a.weightCategory!),
                  if (a.bodyweight != null)
                    _InfoRow('Waga ciała', '${a.bodyweight} kg'),
                  if (a.gender != null)
                    _InfoRow(
                      'Płeć',
                      a.gender == 'male'
                          ? 'Mężczyzna'
                          : a.gender == 'female'
                          ? 'Kobieta'
                          : a.gender!,
                    ),
                  _InfoRow('Status', a.isActive ? 'Aktywny' : 'Nieaktywny'),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SinclairStrip extends StatelessWidget {
  final double value;
  final Color primary;

  const _SinclairStrip({required this.value, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: primary),
          const SizedBox(width: 10),
          Text(
            'Najlepszy Sinclair (zawody)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(2),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePointCard extends StatelessWidget {
  final AthleteChartPoint p;
  const _SinglePointCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jeden zapis na wykresie',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.date,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          '${p.total.toStringAsFixed(0)} kg · rwanie ${p.snatch.toStringAsFixed(0)} · podrzut ${p.cleanAndJerk.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
      ],
    );
  }
}

class _PublicStatsRow extends StatelessWidget {
  final PublicStartStats stats;
  final Color primary;

  const _PublicStatsRow({required this.stats, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SlaviaUi.cardShell(
        context,
        borderTint: primary.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _miniStat('Starty', '${stats.totalStarts}', context)),
          Expanded(
            child: _miniStat(
              'Śr. total',
              stats.avgTotal != null ? '${stats.avgTotal}' : '—',
              context,
            ),
          ),
          Expanded(
            child: _miniStat(
              'Rekord',
              stats.bestTotal != null ? '${stats.bestTotal!.round()} kg' : '—',
              context,
            ),
          ),
          Expanded(
            child: _miniStat(
              'Dni od ost.',
              stats.daysSinceLast != null ? '${stats.daysSinceLast}' : '—',
              context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String a, String b, BuildContext context) {
    return Column(
      children: [
        Text(
          a,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          b,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InsightsGrid extends StatelessWidget {
  final AthleteAnalyticsStats stats;
  final Color primary;
  final Color tertiary;

  const _InsightsGrid({
    required this.stats,
    required this.primary,
    required this.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SlaviaUi.cardShell(
        context,
        borderTint: tertiary.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('Zawody', '${stats.competitions}', primary),
              _chip('Treningi', '${stats.trainings}', tertiary),
              if (stats.bestTrainingTotal != null)
                _chip(
                  'Best trening',
                  '${stats.bestTrainingTotal!.round()} kg',
                  tertiary,
                ),
              if (stats.formRealisationPct != null)
                _chip(
                  'Realizacja formy',
                  '${stats.formRealisationPct}%',
                  primary,
                ),
              if (stats.trendKgLast90Days != null)
                _chip(
                  'Trend 90 dni',
                  '${stats.trendKgLast90Days! > 0 ? '+' : ''}${stats.trendKgLast90Days} kg',
                  primary,
                ),
              _chip('PB w serii', '${stats.pbCount}', primary),
              if (stats.daysSinceLastEntry != null)
                _chip(
                  'Ostatni wpis',
                  '${stats.daysSinceLastEntry} d${stats.lastEntryKind == 'training' ? ' · trening' : ' · zawody'}',
                  Theme.of(context).colorScheme.onSurface,
                ),
              if (stats.bestSinclairTraining != null)
                _chip(
                  'Sinclair trening',
                  stats.bestSinclairTraining!.toStringAsFixed(2),
                  tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String k, String v, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.withValues(alpha: 0.85),
            ),
          ),
          Text(
            v,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _InfoTable extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: SlaviaUi.cardShell(context),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: cs.outline.withValues(alpha: 0.12),
                      ),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.value.label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                Text(
                  e.value.value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

bool canViewAthleteTrainingData(String athleteId, AuthProvider auth) {
  final roles = auth.user?.roles ?? [];
  if (roles.any((r) => r == 'Trainer' || r == 'Admin' || r == 'SuperAdmin'))
    return true;
  return auth.user?.athleteId == athleteId;
}
