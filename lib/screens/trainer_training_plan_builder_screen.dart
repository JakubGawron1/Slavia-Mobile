import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
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

class _EditorRow {
  String id;
  final int dayOfWeek;
  String? exerciseId;
  int sortOrder;

  _EditorRow({
    required this.id,
    required this.dayOfWeek,
    this.exerciseId,
    required this.sortOrder,
  });

  factory _EditorRow.fromItem(TrainingPlanItem i) {
    return _EditorRow(
      id: i.id,
      dayOfWeek: i.dayOfWeek,
      exerciseId: i.exerciseId,
      sortOrder: i.sortOrder,
    );
  }
}

class _RowTc {
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController intensity;
  final TextEditingController notes;
  final TextEditingController customName;

  _RowTc({
    required this.sets,
    required this.reps,
    required this.weight,
    required this.intensity,
    required this.notes,
    required this.customName,
  });

  factory _RowTc.fromItem(TrainingPlanItem i) {
    return _RowTc(
      sets: TextEditingController(text: i.sets?.toString() ?? ''),
      reps: TextEditingController(text: i.reps?.toString() ?? ''),
      weight: TextEditingController(text: i.weightKg?.toString() ?? ''),
      intensity: TextEditingController(text: i.intensityPercent?.toString() ?? ''),
      notes: TextEditingController(text: i.notes ?? ''),
      customName: TextEditingController(text: i.customExerciseName ?? ''),
    );
  }

  factory _RowTc.emptyDefaults() {
    return _RowTc(
      sets: TextEditingController(text: '3'),
      reps: TextEditingController(text: '5'),
      weight: TextEditingController(),
      intensity: TextEditingController(),
      notes: TextEditingController(),
      customName: TextEditingController(),
    );
  }

  PlanItemPutPayload toPayload({
    required int dayOfWeek,
    required String? exerciseId,
    required int sortOrder,
  }) {
    return PlanItemPutPayload(
      dayOfWeek: dayOfWeek,
      exerciseId: exerciseId,
      customExerciseName: customName.text.trim(),
      sets: int.tryParse(sets.text.trim()),
      reps: int.tryParse(reps.text.trim()),
      intensityPercent: double.tryParse(
        intensity.text.trim().replaceAll(',', '.'),
      ),
      weightKg: double.tryParse(weight.text.trim().replaceAll(',', '.')),
      notes: notes.text,
      sortOrder: sortOrder,
    );
  }

  void dispose() {
    sets.dispose();
    reps.dispose();
    weight.dispose();
    intensity.dispose();
    notes.dispose();
    customName.dispose();
  }
}

/// Edycja jednostek planu — odpowiednik `TrainingPlanBuilder.vue` na WWW.
class TrainerTrainingPlanBuilderScreen extends StatefulWidget {
  final String planId;

  const TrainerTrainingPlanBuilderScreen({super.key, required this.planId});

  @override
  State<TrainerTrainingPlanBuilderScreen> createState() =>
      _TrainerTrainingPlanBuilderScreenState();
}

class _TrainerTrainingPlanBuilderScreenState
    extends State<TrainerTrainingPlanBuilderScreen> {
  List<Exercise> _exercises = [];
  final List<_EditorRow> _rows = [];
  final Map<String, _RowTc> _tc = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _disposeAllTc();
    super.dispose();
  }

  void _disposeAllTc() {
    for (final t in _tc.values) {
      t.dispose();
    }
    _tc.clear();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        api.getTrainingPlanItems(widget.planId),
        api.getExercises(),
      ]);
      final items = results[0] as List<TrainingPlanItem>;
      final exercises = results[1] as List<Exercise>;
      if (!mounted) return;
      _disposeAllTc();
      _rows.clear();
      for (final item in items) {
        final r = _EditorRow.fromItem(item);
        _rows.add(r);
        _tc[r.id] = _RowTc.fromItem(item);
      }
      setState(() {
        _exercises = exercises;
        for (final r in _rows) {
          if (r.exerciseId != null &&
              !exercises.any((e) => e.id == r.exerciseId)) {
            r.exerciseId = null;
          }
        }
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

  List<_EditorRow> _rowsForDay(int day) {
    return _rows.where((r) => r.dayOfWeek == day).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void _addRow(int day) {
    final dayRows = _rowsForDay(day);
    final id = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final row = _EditorRow(
      id: id,
      dayOfWeek: day,
      sortOrder: dayRows.length,
    );
    setState(() {
      _rows.add(row);
      _tc[id] = _RowTc.emptyDefaults();
    });
  }

  void _removeRow(String id) {
    setState(() {
      _rows.removeWhere((r) => r.id == id);
      _tc.remove(id)?.dispose();
    });
  }

  void _moveRow(String id, int day, int dir) {
    final list = _rowsForDay(day);
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final j = idx + dir;
    if (j < 0 || j >= list.length) return;
    final a = list[idx];
    final b = list[j];
    setState(() {
      final t = a.sortOrder;
      a.sortOrder = b.sortOrder;
      b.sortOrder = t;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final payloads = <PlanItemPutPayload>[];
      for (final r in _rows) {
        final tc = _tc[r.id];
        if (tc == null) continue;
        payloads.add(
          tc.toPayload(
            dayOfWeek: r.dayOfWeek,
            exerciseId: r.exerciseId,
            sortOrder: r.sortOrder,
          ),
        );
      }
      payloads.sort((a, b) {
        final da = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (da != 0) return da;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      await api.putTrainingPlanItems(widget.planId, payloads);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan treningowy został zaktualizowany')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _safeDropdownExerciseId(_EditorRow r) {
    if (r.exerciseId == null) return null;
    if (!_exercises.any((e) => e.id == r.exerciseId)) return null;
    return r.exerciseId;
  }

  String _exerciseLabel(_EditorRow r) {
    if (r.exerciseId != null) {
      for (final e in _exercises) {
        if (e.id == r.exerciseId) return e.name;
      }
      return 'Ćwiczenie ze słownika';
    }
    final t = _tc[r.id]?.customName.text.trim() ?? '';
    return t.isEmpty ? 'Własna nazwa' : t;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jednostki planu'),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Zapisz'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Ponów')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    children: [
                      for (var d = 1; d <= 7; d++) ...[
                        _dayBlock(context, d, primary),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Zapisz plan'),
            ),
    );
  }

  Widget _dayBlock(BuildContext context, int day, Color primary) {
    final rows = _rowsForDay(day);
    return Container(
      decoration: SlaviaUi.cardShell(context, borderTint: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _kDayNames[day - 1],
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _addRow(day),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Dodaj'),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Text(
                'Brak jednostek — dodaj ćwiczenie.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              return _rowTile(context, r, idx, rows.length, primary);
            }),
        ],
      ),
    );
  }

  Widget _rowTile(
    BuildContext context,
    _EditorRow r,
    int indexInDay,
    int dayCount,
    Color primary,
  ) {
    final tc = _tc[r.id];
    if (tc == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Wyżej',
                      onPressed: indexInDay == 0 ? null : () => _moveRow(r.id, r.dayOfWeek, -1),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Niżej',
                      onPressed: indexInDay >= dayCount - 1
                          ? null
                          : () => _moveRow(r.id, r.dayOfWeek, 1),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _exerciseLabel(r),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ćwiczenie ze słownika',
                          isDense: true,
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
                            value: _safeDropdownExerciseId(r),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('— Własna nazwa —'),
                              ),
                              ..._exercises.map(
                                (ex) => DropdownMenuItem<String?>(
                                  value: ex.id,
                                  child: Text(
                                    ex.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => r.exerciseId = v);
                            },
                          ),
                        ),
                      ),
                      if (r.exerciseId == null) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: tc.customName,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa własna',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Usuń',
                  color: cs.error,
                  onPressed: () => _removeRow(r.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tc.sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: tc.reps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Powtórzenia',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tc.weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'kg',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: tc.intensity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '% intens.',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tc.notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notatka / wskazówki',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
