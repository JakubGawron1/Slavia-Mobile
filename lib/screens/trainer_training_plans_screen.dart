import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/athlete.dart';
import '../models/training_plan.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import 'trainer_training_plan_builder_screen.dart';

/// Jak middleware `trainer.ts` na WWW: trener lub superadmin.
bool _canTrainerPanelPlans(List<String> roles) {
  return roles.contains('Trainer') || roles.contains('SuperAdmin');
}

String _todayIso() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

const _kStatuses = [
  ('planned', 'Zaplanowany'),
  ('active', 'Aktywny'),
  ('paused', 'Wstrzymany'),
  ('completed', 'Zakończony'),
];

String _normPlanStatus(String s) {
  const ok = {'planned', 'active', 'paused', 'completed'};
  return ok.contains(s) ? s : 'planned';
}

/// Bez `DropdownButtonFormField.value` (deprecacja Flutter 3.33+).
Widget _planStatusChipPicker({
  required BuildContext context,
  required String status,
  required ValueChanged<String> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Status',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kStatuses.map((e) {
          final sel = status == e.$1;
          return FilterChip(
            label: Text(e.$2),
            selected: sel,
            onSelected: (_) => onChanged(e.$1),
          );
        }).toList(),
      ),
    ],
  );
}

/// Parity z `/trainer/plany` na WWW.
class TrainerTrainingPlansScreen extends StatefulWidget {
  const TrainerTrainingPlansScreen({super.key});

  @override
  State<TrainerTrainingPlansScreen> createState() =>
      _TrainerTrainingPlansScreenState();
}

class _TrainerTrainingPlansScreenState extends State<TrainerTrainingPlansScreen> {
  List<Athlete> _athletes = [];
  String? _selectedAthleteId;
  Future<List<TrainingPlan>>? _plansFuture;
  bool _loadingAthletes = true;
  String? _athletesError;
  String? _duplicatingPlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAthletes());
  }

  Future<void> _loadAthletes() async {
    setState(() {
      _loadingAthletes = true;
      _athletesError = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getAthletesAdmin();
      if (!mounted) return;
      setState(() {
        _athletes = list;
        _loadingAthletes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _athletesError = '$e';
        _loadingAthletes = false;
      });
    }
  }

  void _setAthlete(String? id) {
    setState(() {
      _selectedAthleteId = id;
      if (id == null || id.isEmpty) {
        _plansFuture = null;
      } else {
        _plansFuture = Provider.of<ApiService>(context, listen: false)
            .getTrainingPlansForAthlete(id);
      }
    });
  }

  Future<void> _reloadPlans() async {
    final id = _selectedAthleteId;
    if (id == null || id.isEmpty) return;
    final api = Provider.of<ApiService>(context, listen: false);
    final fut = api.getTrainingPlansForAthlete(id);
    setState(() => _plansFuture = fut);
    await fut;
    if (mounted) setState(() {});
  }

  void _disposeControllers(
    TextEditingController a,
    TextEditingController b,
    TextEditingController c,
    TextEditingController d,
  ) {
    a.dispose();
    b.dispose();
    c.dispose();
    d.dispose();
  }

  Future<void> _showCreatePlanDialog() async {
    final athleteId = _selectedAthleteId;
    if (athleteId == null) return;

    final titleC = TextEditingController();
    final goalC = TextEditingController();
    final weekC = TextEditingController(text: _todayIso());
    final coachC = TextEditingController();
    var status = _normPlanStatus('planned');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nowy plan treningowy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Tytuł',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weekC,
                  decoration: const InputDecoration(
                    labelText: 'Start tygodnia (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _planStatusChipPicker(
                  context: ctx,
                  status: status,
                  onChanged: (v) => setLocal(() => status = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalC,
                  decoration: const InputDecoration(
                    labelText: 'Cel (opcjonalnie)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coachC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notatka dla zawodnika',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Zapisz plan'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      _disposeControllers(titleC, goalC, weekC, coachC);
      return;
    }

    final title = titleC.text.trim();
    final goal = goalC.text.trim();
    final week = weekC.text.trim();
    final coach = coachC.text.trim();
    _disposeControllers(titleC, goalC, weekC, coachC);

    if (!mounted) return;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj tytuł planu')),
      );
      return;
    }

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.createTrainingPlan(
        athleteId: athleteId,
        title: title,
        goal: goal.isEmpty ? null : goal,
        weekStart: week,
        status: status,
        coachNote: coach.isEmpty ? null : coach,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan dodany')),
      );
      await _reloadPlans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  Future<void> _showEditMetaDialog(TrainingPlan p) async {
    final titleC = TextEditingController(text: p.title);
    final goalC = TextEditingController(text: p.goal ?? '');
    final weekC = TextEditingController(text: p.weekStart);
    final coachC = TextEditingController(text: p.coachNote ?? '');
    var status = _normPlanStatus(p.status);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edytuj plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Tytuł',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weekC,
                  decoration: const InputDecoration(
                    labelText: 'Start tygodnia (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _planStatusChipPicker(
                  context: ctx,
                  status: status,
                  onChanged: (v) => setLocal(() => status = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalC,
                  decoration: const InputDecoration(
                    labelText: 'Cel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coachC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notatka trenera',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    final title = titleC.text.trim();
    final goal = goalC.text.trim();
    final week = weekC.text.trim();
    final coach = coachC.text.trim();
    _disposeControllers(titleC, goalC, weekC, coachC);

    if (ok != true || !mounted) return;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tytuł nie może być pusty')),
      );
      return;
    }

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.updateTrainingPlan(
        p.id,
        title: title,
        goal: goal.isEmpty ? null : goal,
        weekStart: week,
        status: status,
        coachNote: coach.isEmpty ? null : coach,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano plan')),
      );
      await _reloadPlans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  Future<void> _confirmDelete(TrainingPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć plan?'),
        content: Text('Plan „${p.title}” zostanie trwale usunięty.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.deleteTrainingPlan(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan usunięty')),
      );
      await _reloadPlans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    }
  }

  Future<void> _duplicate(TrainingPlan p) async {
    final athleteId = _selectedAthleteId;
    if (athleteId == null) return;
    setState(() => _duplicatingPlanId = p.id);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.duplicateTrainingPlan(source: p, athleteId: athleteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utworzono kopię planu')),
      );
      await _reloadPlans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd kopiowania: $e')),
      );
    } finally {
      if (mounted) setState(() => _duplicatingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roles = auth.user?.roles ?? <String>[];
    if (!_canTrainerPanelPlans(roles)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plany treningowe')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Dostęp tylko dla trenera lub superadministratora (jak panel trenera na stronie).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plany — trener'),
        actions: [
          IconButton(
            tooltip: 'Odśwież listę zawodników',
            onPressed: _loadingAthletes ? null : _loadAthletes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loadingAthletes
          ? const Center(child: CircularProgressIndicator())
          : _athletesError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_athletesError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadAthletes,
                          child: const Text('Ponów'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlaviaUi.sectionHeader(
                            context,
                            'Zawodnik',
                            accent: primary,
                            icon: Icons.people_outline_rounded,
                          ),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Wybierz zawodnika',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsetsDirectional.only(
                                start: 12,
                                end: 4,
                                top: 4,
                                bottom: 4,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                value: _selectedAthleteId,
                                hint: const Text('— Wybierz —'),
                                items: _athletes
                                    .map(
                                      (a) => DropdownMenuItem<String?>(
                                        value: a.id,
                                        child: Text(
                                          a.fullName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _setAthlete,
                              ),
                            ),
                          ),
                          if (_selectedAthleteId != null) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _showCreatePlanDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nowy plan'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _selectedAthleteId == null
                          ? Center(
                              child: Text(
                                'Wybierz zawodnika, aby zarządzać planami.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : _plansFuture == null
                              ? const Center(child: CircularProgressIndicator())
                              : FutureBuilder<List<TrainingPlan>>(
                                  future: _plansFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        !snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('${snapshot.error}'),
                                              const SizedBox(height: 12),
                                              FilledButton(
                                                onPressed: _reloadPlans,
                                                child: const Text('Ponów'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    final plans = snapshot.data ?? [];
                                    if (plans.isEmpty) {
                                      return RefreshIndicator(
                                        onRefresh: _reloadPlans,
                                        child: ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(24),
                                          children: [
                                            const SizedBox(height: 48),
                                            Text(
                                              'Brak planów treningowych.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return RefreshIndicator(
                                      onRefresh: _reloadPlans,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          24,
                                        ),
                                        itemCount: plans.length,
                                        itemBuilder: (context, i) {
                                          final p = plans[i];
                                          final dup =
                                              _duplicatingPlanId == p.id;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Container(
                                              decoration: SlaviaUi.cardShell(
                                                context,
                                                borderTint: primary,
                                              ),
                                              padding: const EdgeInsets.all(
                                                14,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Chip(
                                                        label: Text(
                                                          p.status,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'od ${p.weekStart}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Theme.of(
                                                            context,
                                                          )
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    p.title,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  if (p.goal != null &&
                                                      p.goal!.trim().isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        top: 6,
                                                      ),
                                                      child: Text(
                                                        p.goal!,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          height: 1.35,
                                                          color: Theme.of(
                                                            context,
                                                          )
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(height: 10),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      4,
                                                    ),
                                                    child: LinearProgressIndicator(
                                                      value: (p.progressPercent
                                                              .clamp(0, 100)) /
                                                          100,
                                                      minHeight: 6,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${p.progressPercent}% postępu zawodnika',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.55,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      FilledButton.tonalIcon(
                                                        onPressed: () {
                                                          Navigator.push<void>(
                                                            context,
                                                            MaterialPageRoute<
                                                                void>(
                                                              builder: (_) =>
                                                                  TrainerTrainingPlanBuilderScreen(
                                                                planId: p.id,
                                                              ),
                                                            ),
                                                          ).then((_) {
                                                            _reloadPlans();
                                                          });
                                                        },
                                                        icon: const Icon(
                                                          Icons
                                                              .tune_rounded,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'Jednostki',
                                                        ),
                                                      ),
                                                      IconButton.filledTonal(
                                                        tooltip: 'Edytuj',
                                                        onPressed: () =>
                                                            _showEditMetaDialog(
                                                          p,
                                                        ),
                                                        icon: const Icon(
                                                          Icons.edit_rounded,
                                                        ),
                                                      ),
                                                      IconButton.filledTonal(
                                                        tooltip: 'Duplikuj',
                                                        onPressed: dup
                                                            ? null
                                                            : () =>
                                                                _duplicate(p),
                                                        icon: dup
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons.copy_rounded,
                                                              ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Usuń',
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .error,
                                                        onPressed: () =>
                                                            _confirmDelete(p),
                                                        icon: const Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                        ),
                                                      ),
                                                    ],
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
                    ),
                  ],
                ),
    );
  }
}
