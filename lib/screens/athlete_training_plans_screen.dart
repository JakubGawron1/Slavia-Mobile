import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/training_plan.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';

const _kDayNames = [
  'Poniedziałek',
  'Wtorek',
  'Środa',
  'Czwartek',
  'Piątek',
  'Sobota',
  'Niedziela',
];

const _kStatuses = ['planned', 'active', 'paused', 'completed'];

String _statusLabel(String s) {
  switch (s) {
    case 'planned':
      return 'Zaplanowany';
    case 'active':
      return 'Aktywny';
    case 'paused':
      return 'Wstrzymany';
    case 'completed':
      return 'Zakończony';
    default:
      return s;
  }
}

Color _statusColor(String s, ColorScheme cs) {
  switch (s) {
    case 'active':
      return cs.tertiary;
    case 'completed':
      return cs.primary;
    case 'paused':
      return cs.tertiaryContainer;
    default:
      return cs.outline;
  }
}

class _PlanDraft {
  String status;
  int progressPercent;

  _PlanDraft({
    required this.status,
    required this.progressPercent,
  });
}

bool _isPlanCurrentWeek(String weekStart) {
  final parts = weekStart.split('-');
  if (parts.length != 3) return false;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return false;
  final start = DateTime(y, m, d);
  final end = start.add(const Duration(days: 7));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return !today.isBefore(start) && today.isBefore(end);
}

int _defaultDayForPlan(TrainingPlan plan) {
  if (_isPlanCurrentWeek(plan.weekStart)) {
    return DateTime.now().weekday;
  }
  return 1;
}

void _normalizeDraftForProgress(_PlanDraft d) {
  if (d.progressPercent >= 100 && d.status != 'completed') {
    d.status = 'completed';
    return;
  }
  if (d.progressPercent > 0 && d.status == 'planned') {
    d.status = 'active';
  }
}

/// Lista planów i edycja postępu — jak `/athlete/plany` na WWW.
class AthleteTrainingPlansScreen extends StatefulWidget {
  const AthleteTrainingPlansScreen({super.key});

  @override
  State<AthleteTrainingPlansScreen> createState() =>
      _AthleteTrainingPlansScreenState();
}

class _AthleteTrainingPlansScreenState extends State<AthleteTrainingPlansScreen> {
  final Map<String, _PlanDraft> _drafts = {};
  final Map<String, TextEditingController> _noteControllers = {};
  Future<List<TrainingPlan>>? _plansFuture;
  String? _savingPlanId;

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _reload() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final fut = api.getMyTrainingPlans();
    if (mounted) {
      setState(() => _plansFuture = fut);
    }
    final list = await fut;
    if (!mounted) return;
    setState(() {
      for (final p in list) {
        if (!_drafts.containsKey(p.id)) {
          _drafts[p.id] = _PlanDraft(
            status: p.status,
            progressPercent: p.progressPercent,
          );
          _noteControllers[p.id] = TextEditingController(text: p.athleteNote ?? '');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _saveProgress(String planId) async {
    final draft = _drafts[planId];
    final note = _noteControllers[planId]?.text ?? '';
    if (draft == null) return;

    setState(() => _savingPlanId = planId);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.patchMyTrainingPlanProgress(
        planId,
        status: draft.status,
        progressPercent: draft.progressPercent,
        athleteNote: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postęp został zaktualizowany')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingPlanId = null);
    }
  }

  void _resetDraft(String planId, TrainingPlan p) {
    final d = _drafts[planId];
    if (d != null) {
      d.status = p.status;
      d.progressPercent = p.progressPercent;
    }
    _noteControllers[planId]?.text = p.athleteNote ?? '';
    setState(() {});
  }

  void _setDraftStatus(
    BuildContext context,
    String planId,
    TrainingPlan p,
    String next,
  ) {
    final d = _drafts[planId];
    if (d == null) return;
    if (next == 'completed' && d.progressPercent < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aby zakończyć plan, ustaw 100% postępu na suwaku.',
          ),
        ),
      );
      return;
    }
    d.status = next;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final athleteId = auth.user?.athleteId;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Plany treningowe')),
      body: athleteId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Brak profilu zawodnika — plany są widoczne po powiązaniu konta ze zawodnikiem.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _plansFuture == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<TrainingPlan>>(
              future: _plansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Nie udało się wczytać planów: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final plans = snapshot.data ?? [];

                if (plans.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 48),
                        Text(
                          'Nie masz jeszcze przypisanych planów treningowych.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final p = plans[index];
                      final d = _drafts[p.id]!;
                      final cs = Theme.of(context).colorScheme;
                      final saving = _savingPlanId == p.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: SlaviaUi.cardShell(context, borderTint: primary),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      _statusLabel(p.status),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: _statusColor(p.status, cs)
                                        .withValues(alpha: 0.2),
                                  ),
                                  Chip(
                                    avatar: const Icon(Icons.calendar_today, size: 14),
                                    label: Text(
                                      'od ${p.weekStart}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (p.goal != null && p.goal!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  p.goal!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'Postęp: ${_statusLabel(d.status)} • ${d.progressPercent}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Slider(
                                value: d.progressPercent.toDouble().clamp(0, 100),
                                max: 100,
                                divisions: 20,
                                label: '${d.progressPercent}%',
                                onChanged: saving
                                    ? null
                                    : (v) {
                                        setState(() {
                                          d.progressPercent = v.round();
                                          _normalizeDraftForProgress(d);
                                        });
                                      },
                              ),
                              Text(
                                'Stan (wybierz)',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _kStatuses.map((s) {
                                  final sel = d.status == s;
                                  return FilterChip(
                                    label: Text(_statusLabel(s)),
                                    selected: sel,
                                    onSelected: saving
                                        ? null
                                        : (_) => _setDraftStatus(context, p.id, p, s),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _noteControllers[p.id],
                                enabled: !saving,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notatka dla trenera (opcjonalnie)',
                                  hintText: 'Np. jak poszło, co było trudne…',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Auto: 100% → zakończony, >0% przy „zaplanowany” → aktywny',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: saving ? null : () => _saveProgress(p.id),
                                      child: saving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Zapisz'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: saving ? null : () => _resetDraft(p.id, p),
                                    child: const Text('Cofnij'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          Navigator.push<void>(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  _TrainingPlanDetailPage(plan: p),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.visibility_rounded, size: 20),
                                  label: const Text('Szczegóły jednostek'),
                                ),
                              ),
                            ],
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
}

class _TrainingPlanDetailPage extends StatefulWidget {
  final TrainingPlan plan;

  const _TrainingPlanDetailPage({required this.plan});

  @override
  State<_TrainingPlanDetailPage> createState() => _TrainingPlanDetailPageState();
}

class _TrainingPlanDetailPageState extends State<_TrainingPlanDetailPage> {
  List<TrainingPlanItem> _items = [];
  bool _loading = true;
  String? _error;
  late int _activeDay;

  @override
  void initState() {
    super.initState();
    _activeDay = _defaultDayForPlan(widget.plan);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final items = await api.getTrainingPlanItems(widget.plan.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<TrainingPlanItem> _itemsForDay(int day) {
    return _items
        .where((i) => i.dayOfWeek == day)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    return Scaffold(
      appBar: AppBar(title: Text(p.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (p.coachNote != null && p.coachNote!.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                        border: Border.all(color: primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UWAGI OD TRENERA',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.coachNote!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: cs.error)),
                    ),
                  Text(
                    'Dzień tygodnia',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (i) {
                      final dayId = i + 1;
                      final sel = _activeDay == dayId;
                      return FilterChip(
                        label: Text(
                          _kDayNames[i].substring(0, 3),
                          style: TextStyle(
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) => setState(() => _activeDay = dayId),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _kDayNames[_activeDay - 1],
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${_itemsForDay(_activeDay).length} ćwiczeń',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_itemsForDay(_activeDay).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Brak wpisów na ten dzień.',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                        ),
                      ),
                    )
                  else
                    ..._itemsForDay(_activeDay).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: SlaviaUi.cardShell(context, borderTint: primary),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _itemMetaLine(item),
                              if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.notes!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: cs.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _itemMetaLine(TrainingPlanItem item) {
    final parts = <String>[];
    if (item.sets != null && item.reps != null) {
      parts.add('${item.sets}×${item.reps}');
    } else if (item.sets != null) {
      parts.add('serie: ${item.sets}');
    } else if (item.reps != null) {
      parts.add('powt.: ${item.reps}');
    }
    if (item.intensityPercent != null) {
      parts.add('${item.intensityPercent!.round()}%');
    }
    if (item.weightKg != null) {
      parts.add('${item.weightKg} kg');
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
