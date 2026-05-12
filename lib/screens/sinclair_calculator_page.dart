import 'package:flutter/material.dart';
import '../utils/sinclair_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class SinclairCalculatorPage extends StatefulWidget {
  const SinclairCalculatorPage({super.key});

  @override
  State<SinclairCalculatorPage> createState() => _SinclairCalculatorPageState();
}

class _SinclairCalculatorPageState extends State<SinclairCalculatorPage> {
  SinclairGender _gender = SinclairGender.male;
  final _bodyweightController = TextEditingController();
  final _totalController = TextEditingController();
  double _coefficient = 0.0;
  double _sinclairTotal = 0.0;

  void _calculate() {
    final bw =
        double.tryParse(_bodyweightController.text.replaceAll(',', '.')) ?? 0.0;
    final total =
        double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      _coefficient = SinclairCalculator.calculateCoefficient(bw, _gender);
      _sinclairTotal = SinclairCalculator.calculateTotal(total, bw, _gender);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kalkulator Sinclair',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Przelicznik na okres 2025–2028',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildDropdown(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _bodyweightController,
                    'Masa ciała (kg)',
                    'np. 81.4',
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_totalController, 'Dwubój (kg)', 'np. 280'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Współczynnik',
                    _coefficient.toStringAsFixed(4),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                    'Punkty Sinclair',
                    _sinclairTotal.toStringAsFixed(2),
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildInfoBox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<SinclairGender>(
      key: ValueKey(_gender),
      initialValue: _gender,
      decoration: const InputDecoration(
        labelText: 'Płeć',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: SinclairGender.male, child: Text('Mężczyzna')),
        DropdownMenuItem(value: SinclairGender.female, child: Text('Kobieta')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _gender = val);
          _calculate();
        }
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Przelicznik zgodny z oficjalnym wzorem IWF na lata 2025–2028.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
