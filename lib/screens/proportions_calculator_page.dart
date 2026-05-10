import 'package:flutter/material.dart';
import '../utils/weightlifting_ratios.dart';

class ProportionsCalculatorPage extends StatefulWidget {
  const ProportionsCalculatorPage({super.key});

  @override
  State<ProportionsCalculatorPage> createState() => _ProportionsCalculatorPageState();
}

class _ProportionsCalculatorPageState extends State<ProportionsCalculatorPage> {
  final Map<ExerciseId, TextEditingController> _controllers = {
    for (var id in ExerciseId.values) id: TextEditingController()
  };

  List<RatioResult> _results = [];

  void _calculate() {
    final inputs = <ExerciseId, double?>{};
    for (var entry in _controllers.entries) {
      inputs[entry.key] = double.tryParse(entry.value.text.replaceAll(',', '.'));
    }
    setState(() {
      _results = WeightliftingRatios.compute(inputs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Złote Proporcje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Wpisz swoje maxy (1RM)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInput(ExerciseId.snatch, 'Rwanie'),
            _buildInput(ExerciseId.cleanJerk, 'Podrzut'),
            _buildInput(ExerciseId.backSquat, 'Przysiad z tyłu'),
            _buildInput(ExerciseId.frontSquat, 'Przysiad z przodu'),
            const SizedBox(height: 24),
            const Text(
              'Sugerowane zakresy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._results.map((r) => _buildResultCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(ExerciseId id, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: _controllers[id],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _calculate(),
      ),
    );
  }

  Widget _buildResultCard(RatioResult r) {
    if (r.minKg == null) return const SizedBox.shrink();

    Color statusColor = Colors.grey;
    if (r.status == 'in_range') statusColor = Colors.green;
    if (r.status == 'below') statusColor = Colors.orange;
    if (r.status == 'above') statusColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.pl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status == 'in_range' ? 'W normie' : (r.status == 'below' ? 'Poniżej' : 'Powyżej'),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Od: ${r.fromPl}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sugerowane: ${r.minKg!.toStringAsFixed(1)} - ${r.maxKg!.toStringAsFixed(1)} kg'),
                if (r.actualKg != null)
                  Text('Masz: ${r.actualKg!.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (r.note != null) ...[
              const SizedBox(height: 8),
              Text(r.note!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
