import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../main.dart';
import '../models/recovery_log.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Dziennik regeneracji — to samo API co `/api/recovery` na WWW.
class RecoveryJournalScreen extends StatefulWidget {
  const RecoveryJournalScreen({super.key});

  @override
  State<RecoveryJournalScreen> createState() => _RecoveryJournalScreenState();
}

class _RecoveryJournalScreenState extends State<RecoveryJournalScreen> {
  Future<List<RecoveryLog>>? _future;

  Future<void> _reload() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final f = api.getMyRecoveryLogs();
    setState(() => _future = f);
    await f;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reload());
    });
  }

  Future<void> _openEditor({RecoveryLog? existing}) async {
    final athleteId = Provider.of<AuthProvider>(context, listen: false).user?.athleteId;
    if (athleteId == null || athleteId.isEmpty) return;

    DateTime day = existing != null
        ? DateTime.tryParse(existing.date) ?? DateTime.now()
        : DateTime.now();
    var sleep = existing?.sleepHours ?? 7.5;
    var fatigue = existing?.fatigueLevel ?? 5;
    var soreness = existing?.sorenessLevel ?? 5;
    var readiness = existing?.readinessLevel ?? 6;
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SlaviaUi.radiusXl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Nowy wpis' : 'Edycja wpisu',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Data', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      DateFormat.yMMMMEEEEd('pl_PL').format(day),
                      style: GoogleFonts.outfit(fontSize: 15),
                    ),
                    trailing: IconButton.filledTonal(
                      icon: const Icon(Icons.calendar_month_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: day,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          locale: const Locale('pl', 'PL'),
                        );
                        if (picked != null) setLocal(() => day = picked);
                      },
                    ),
                  ),
                  Text('Sen (h): ${sleep.toStringAsFixed(1)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  Slider(
                    value: sleep.clamp(0.0, 24.0),
                    max: 24,
                    divisions: 48,
                    label: '${sleep.toStringAsFixed(1)} h',
                    onChanged: (v) => setLocal(() => sleep = v),
                  ),
                  _sliderRow(ctx, 'Zmęczenie', fatigue, (v) => setLocal(() => fatigue = v)),
                  _sliderRow(ctx, 'Ból mięśni', soreness, (v) => setLocal(() => soreness = v)),
                  _sliderRow(ctx, 'Gotowość', readiness, (v) => setLocal(() => readiness = v)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: SlaviaUi.filledField(context, label: 'Notatka (opcjonalnie)'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Zapisz'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final noteStr = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (saved != true || !mounted) return;

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.upsertMyRecoveryLog(
        date: _isoDate(day),
        sleepHours: sleep,
        fatigueLevel: fatigue,
        sorenessLevel: soreness,
        readinessLevel: readiness,
        note: noteStr.isEmpty ? null : noteStr,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano check-in regeneracji')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  Widget _sliderRow(
    BuildContext context,
    String label,
    int value,
    void Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value / 10', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final athleteId = auth.user?.athleteId;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Regeneracja')),
      floatingActionButton: athleteId != null && athleteId.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dzisiaj'),
            )
          : null,
      body: athleteId == null || athleteId.isEmpty
          ? SlaviaUi.emptyState(
              context,
              icon: Icons.person_off_outlined,
              title: 'Wymagany profil zawodnika',
              subtitle: 'Dziennik regeneracji jest dostępny po powiązaniu konta ze zawodnikiem.',
            )
          : FutureBuilder<List<RecoveryLog>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _reload, child: const Text('Ponów')),
                        ],
                      ),
                    ),
                  );
                }
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SlaviaUi.emptyState(
                          context,
                          icon: Icons.spa_outlined,
                          title: 'Brak wpisów',
                          subtitle: 'Dodaj pierwszy check-in — sen, zmęczenie i gotowość do treningu.',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final r = logs[i];
                      final d = DateTime.tryParse(r.date) ?? DateTime.now();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _openEditor(existing: r);
                            },
                            child: Ink(
                              decoration: SlaviaUi.cardShell(context, borderTint: primary),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat.yMMMMEEEEd('pl_PL').format(d),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    children: [
                                      _chip(context, Icons.bedtime_outlined, '${r.sleepHours.toStringAsFixed(1)} h snu'),
                                      _chip(context, Icons.battery_alert_rounded, 'Zmęczenie ${r.fatigueLevel}/10'),
                                      _chip(context, Icons.fitness_center_rounded, 'Ból ${r.sorenessLevel}/10'),
                                      _chip(context, Icons.bolt_rounded, 'Gotowość ${r.readinessLevel}/10'),
                                    ],
                                  ),
                                  if (r.note != null && r.note!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      r.note!.trim(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        height: 1.35,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(text, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
      visualDensity: VisualDensity.compact,
      backgroundColor: cs.primary.withValues(alpha: 0.08),
    );
  }
}
