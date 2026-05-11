import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/athlete.dart';
import '../ui/slavia_ui.dart';
import 'athlete_detail_screen.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  late Future<List<Athlete>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Athlete>> _load() {
    final api = Provider.of<ApiService>(context, listen: false);
    return api.getAthletes();
  }

  Future<void> _onRefresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<List<Athlete>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 56, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Nie udało się wczytać listy',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Spróbuj ponownie'),
                    ),
                  ],
                ),
              ),
            );
          }
          final athletes = snapshot.data ?? [];
          if (athletes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_2_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Brak zawodników',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SlaviaUi.sectionHeader(
                          context,
                          'Kadra klubu',
                          accent: cs.primary,
                          icon: Icons.fitness_center_rounded,
                        ),
                        Text(
                          'Wyniki i kategorie — spójnie z rankingiem na stronie.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.58),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: athletes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final a = athletes[index];
                      return _AthleteCard(
                        athlete: a,
                        primary: cs.primary,
                        tertiary: cs.tertiary,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final Athlete athlete;
  final Color primary;
  final Color tertiary;

  const _AthleteCard({
    required this.athlete,
    required this.primary,
    required this.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AthleteDetailScreen(
                athleteId: athlete.id,
                title: athlete.fullName,
              ),
            ),
          );
        },
        child: Ink(
          decoration: SlaviaUi.cardShell(
            context,
            borderTint: primary.withValues(alpha: 0.85),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: primary.withValues(alpha: 0.12),
                    backgroundImage: athlete.imageUrl != null
                        ? NetworkImage(athlete.imageUrl!)
                        : null,
                    child: athlete.imageUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: primary.withValues(alpha: 0.85),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (athlete.weightCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Kat. ${athlete.weightCategory}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStat(
                              context,
                              'Rwanie',
                              '${athlete.bestSnatchKg ?? 0} kg',
                            ),
                          ),
                          Expanded(
                            child: _buildStat(
                              context,
                              'Podrzut',
                              '${athlete.bestCleanJerkKg ?? 0} kg',
                            ),
                          ),
                          Expanded(
                            child: _buildStat(
                              context,
                              'Dwubój',
                              '${athlete.totalKg ?? 0} kg',
                              accent: tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value, {
    Color? accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final c = accent ?? cs.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: c,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
