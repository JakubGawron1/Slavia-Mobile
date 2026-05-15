import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/athlete.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/athlete_badges.dart';

/// Osiągnięcia / odznaki zawodnika (jak `AthleteBadges.vue`).
class AthleteAchievementsScreen extends StatefulWidget {
  const AthleteAchievementsScreen({super.key, this.athleteId});

  /// Gdy null — bierze `athleteId` z konta zalogowanego.
  final String? athleteId;

  @override
  State<AthleteAchievementsScreen> createState() => _AthleteAchievementsScreenState();
}

class _AthleteAchievementsScreenState extends State<AthleteAchievementsScreen> {
  Future<({Athlete athlete, int presentCount})>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reload());
    });
  }

  Future<void> _reload() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final id = widget.athleteId ?? auth.user?.athleteId;
    if (id == null || id.isEmpty) {
      setState(() => _future = null);
      return;
    }
    final f = () async {
        final athlete = await api.getAthlete(id);
        var present = 0;
        try {
          final summary = await api.getAttendanceSummary(id);
          present = summary.presentCount;
        } catch (_) {}
        return (athlete: athlete, presentCount: present);
    }();
    setState(() => _future = f);
    await f;
  }

  void _openDetail(AthleteBadgeDef badge) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: badge.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badge.accent.withValues(alpha: 0.35)),
                    ),
                    child: Icon(badge.icon, color: badge.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.label,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          badge.description,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.35,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Poziomy',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(badge.thresholds.length, (i) {
                final t = badge.thresholds[i];
                final ok = badge.current >= t;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ok
                            ? cs.primary.withValues(alpha: 0.35)
                            : cs.outline.withValues(alpha: 0.2),
                      ),
                      color: ok ? cs.primary.withValues(alpha: 0.06) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ok ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                          size: 20,
                          color: ok ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Poziom ${i + 1}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${t.toStringAsFixed(t == t.roundToDouble() ? 0 : 1)} ${badge.unit}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: ok ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Obecnie: ${badge.current.floor()} ${badge.unit}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              if (badge.nextThreshold != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Do kolejnego poziomu: ${(badge.nextThreshold! - badge.current).ceil()} ${badge.unit}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  'Maksymalny poziom!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
  final primary = cs.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Osiągnięcia', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      ),
      body: _future == null
          ? SlaviaUi.emptyState(
              context,
              icon: Icons.person_off_outlined,
              title: 'Brak profilu zawodnika',
              subtitle: 'Powiąż konto ze zawodnikiem na stronie klubu.',
            )
          : FutureBuilder<({Athlete athlete, int presentCount})>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${snap.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _reload, child: const Text('Ponów')),
                        ],
                      ),
                    ),
                  );
                }
                final data = snap.data!;
                final badges = buildAthleteBadges(
                  data.athlete,
                  presentCount: data.presentCount,
                );
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      SlaviaUi.sectionHeader(
                        context,
                        'Twoje odznaki',
                        accent: primary,
                        icon: Icons.military_tech_rounded,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tapnij odznakę, aby zobaczyć poziomy — jak na stronie klubu.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...badges.map((b) {
                        final locked = b.level == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                              onTap: () => _openDetail(b),
                              child: Container(
                                decoration: SlaviaUi.cardShell(
                                  context,
                                  borderTint: b.accent,
                                ).copyWith(
                                  color: locked
                                      ? cs.surface.withValues(alpha: 0.6)
                                      : cs.surface,
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: b.accent.withValues(alpha: locked ? 0.06 : 0.14),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: b.accent.withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Icon(
                                            b.icon,
                                            color: locked
                                                ? cs.onSurface.withValues(alpha: 0.35)
                                                : b.accent,
                                          ),
                                        ),
                                        if (b.level > 0)
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: cs.surface,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: b.accent),
                                              ),
                                              child: Text(
                                                '${b.level}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b.label.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.1,
                                              color: cs.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '${b.current.floor()}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                b.unit,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: cs.onSurface.withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: b.progressPercent / 100,
                                              minHeight: 4,
                                              backgroundColor: cs.outline.withValues(alpha: 0.15),
                                              color: b.accent,
                                            ),
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
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
