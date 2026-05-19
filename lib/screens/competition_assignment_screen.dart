import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/athlete.dart';
import '../models/competition.dart';
import '../models/competition_participant.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart';

/// Kadra: przypisywanie zawodników do zawodów przez API `competition_participants`
/// (`GET`/`PUT /api/competitions/{id}/participants`) — zgodnie z backendem, bez fałszywych wyników.
class CompetitionAssignmentScreen extends StatefulWidget {
  const CompetitionAssignmentScreen({super.key});

  @override
  State<CompetitionAssignmentScreen> createState() =>
      _CompetitionAssignmentScreenState();
}

class _CompetitionAssignmentScreenState
    extends State<CompetitionAssignmentScreen> {
  late Future<List<Competition>> _competitionsFuture;

  @override
  void initState() {
    super.initState();
    _reloadCompetitions();
  }

  void _reloadCompetitions() {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _competitionsFuture = api.getCompetitions());
  }

  Future<void> _onRefresh() async {
    _reloadCompetitions();
    await _competitionsFuture;
  }

  Future<void> _openRosterSheet(Competition competition) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SlaviaUi.radiusXl),
        ),
      ),
      builder: (ctx) => _CompetitionRosterSheet(
        competition: competition,
        api: api,
      ),
    );
    if (mounted) _reloadCompetitions();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final df = DateFormat('d MMM yyyy', 'pl_PL');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Starty zawodników',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<List<Competition>>(
          future: _competitionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              final cs = Theme.of(context).colorScheme;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.cloud_off_rounded, size: 48, color: cs.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Nie udało się wczytać kalendarza zawodów.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              );
            }
            final competitions = snapshot.data ?? [];
            if (competitions.isEmpty) {
              final cs = Theme.of(context).colorScheme;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.event_busy_rounded, size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Brak zawodów w systemie',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gdy admin doda zawody w panelu, pojawią się tutaj do przypisania zawodników.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: competitions.length,
              itemBuilder: (context, index) {
              final c = competitions[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: primary.withValues(alpha: 0.12),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openRosterSheet(c),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.event_note_rounded, color: primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    df.format(c.date),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      c.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.groups_rounded, color: primary.withValues(alpha: 0.85)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}

class _CompetitionRosterSheet extends StatefulWidget {
  const _CompetitionRosterSheet({
    required this.competition,
    required this.api,
  });

  final Competition competition;
  final ApiService api;

  @override
  State<_CompetitionRosterSheet> createState() => _CompetitionRosterSheetState();
}

class _CompetitionRosterSheetState extends State<_CompetitionRosterSheet> {
  late Future<List<CompetitionParticipantBrief>> _rosterFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rosterFuture = widget.api.getCompetitionParticipants(widget.competition.id);
  }

  void _reloadRoster() {
    setState(() {
      _rosterFuture = widget.api.getCompetitionParticipants(widget.competition.id);
    });
  }

  Future<void> _persistIds(List<String> ids) async {
    setState(() => _busy = true);
    try {
      await widget.api.setCompetitionParticipants(widget.competition.id, ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zapisano skład startowy.', style: GoogleFonts.outfit()),
          ),
        );
      }
      _reloadRoster();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisu: $e', style: GoogleFonts.outfit()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addAthlete(Athlete a, List<String> currentIds) async {
    if (currentIds.contains(a.id)) return;
    final next = [...currentIds, a.id];
    await _persistIds(next);
  }

  Future<void> _removeAthlete(String athleteId, String fullName, List<String> currentIds) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Usunąć z listy?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text(
          '$fullName nie będzie widoczny przy tych zawodach (powiadomienia jak na stronie klubu).',
          style: GoogleFonts.outfit(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Anuluj', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Usuń', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final next = currentIds.where((id) => id != athleteId).toList();
    await _persistIds(next);
  }

  Future<void> _showAddDialog(List<String> assignedIds) async {
    final picked = await showDialog<Athlete>(
      context: context,
      builder: (ctx) => _PickAthleteDialog(
        api: widget.api,
        excludeIds: assignedIds.toSet(),
      ),
    );
    if (picked != null && mounted) {
      await _addAthlete(picked, assignedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final h = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: SizedBox(
        height: h,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.competition.title,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                widget.competition.location,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              SlaviaUi.sectionHeader(
                context,
                'Przypisani zawodnicy',
                accent: primary,
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    FutureBuilder<List<CompetitionParticipantBrief>>(
                      future: _rosterFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'Błąd: ${snap.error}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(),
                            ),
                          );
                        }
                        final roster = snap.data ?? [];
                        final ids = roster.map((p) => p.athleteId).toList();
                        if (roster.isEmpty) {
                          return Center(
                            child: Text(
                              'Nikt nie jest jeszcze przypisany.\nDodaj zawodników przyciskiem poniżej.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                height: 1.4,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: roster.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = roster[i];
                            return Material(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _busy
                                    ? null
                                    : () => _removeAthlete(p.athleteId, p.fullName, ids),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.fullName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: cs.error.withValues(alpha: 0.85),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (_busy)
                      Container(
                        color: cs.surface.withValues(alpha: 0.65),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final snap = await _rosterFuture;
                        if (!mounted) return;
                        await _showAddDialog(snap.map((e) => e.athleteId).toList());
                      },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text('Dodaj zawodnika', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 6),
              Text(
                'Usuwanie: dotknij wiersz i potwierdź w oknie.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickAthleteDialog extends StatelessWidget {
  const _PickAthleteDialog({
    required this.api,
    required this.excludeIds,
  });

  final ApiService api;
  final Set<String> excludeIds;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Wybierz zawodnika', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: FutureBuilder<List<Athlete>>(
          future: api.getAthletes(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    friendlyNetworkError(snap.error!),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(),
                  ),
                ),
              );
            }
            final list = (snap.data ?? [])
                .where((a) => a.isActive && !excludeIds.contains(a.id))
                .toList()
              ..sort((a, b) => a.fullName.compareTo(b.fullName));
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'Wszyscy aktywni zawodnicy są już na liście.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final a = list[i];
                return ListTile(
                  title: Text(a.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, a),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Anuluj', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
