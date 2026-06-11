import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';

/// Składki klubowe zawodnika — parity z WWW `/athlete/skladki` (odczyt + zgłoszenie wpłaty).
class MembershipPaymentsScreen extends StatefulWidget {
  const MembershipPaymentsScreen({super.key});

  @override
  State<MembershipPaymentsScreen> createState() =>
      _MembershipPaymentsScreenState();
}

class _MembershipPaymentsScreenState extends State<MembershipPaymentsScreen> {
  PaymentStatusResponse? _status;
  List<PaymentMonthStatusRow> _yearRows = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    try {
      final status = await api.getMyPaymentStatus();
      final rows = await api.getMyPaymentsYear(year: _year);
      if (!mounted) return;
      setState(() {
        _status = status;
        _yearRows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _declarePayment() async {
    setState(() => _submitting = true);
    final api = context.read<ApiService>();
    try {
      await api.createMyPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zgłoszono wpłatę — kadra ją zweryfikuje.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zgłosić wpłaty: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _monthLabel(String ym) {
    const names = [
      '',
      'Sty',
      'Lut',
      'Mar',
      'Kwi',
      'Maj',
      'Cze',
      'Lip',
      'Sie',
      'Wrz',
      'Paź',
      'Lis',
      'Gru',
    ];
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${names[m]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Składka klubowa')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  if (_status != null) ...[
                    SlaviaUi.sectionHeader(
                      context,
                      'Bieżący miesiąc',
                      accent: primary,
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 8),
                    _StatusCard(status: _status!),
                    const SizedBox(height: 12),
                    if (!_status!.isPaid && !_status!.hasStandingOrder)
                      SlaviaUi.primaryButton(
                        context,
                        label: _submitting ? 'Wysyłanie…' : 'Zgłoś wpłatę',
                        icon: Icons.check_circle_outline,
                        onPressed: _submitting ? null : _declarePayment,
                      ),
                    const SizedBox(height: 24),
                  ],
                  SlaviaUi.sectionHeader(
                    context,
                    'Rok $_year',
                    accent: Colors.teal,
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 8),
                  ..._yearRows.map((row) => _MonthRow(
                        label: _monthLabel(row.month),
                        row: row,
                      )),
                ],
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final PaymentStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final paid = status.isPaid;
    final standing = status.hasStandingOrder;
    final color = paid
        ? Colors.green
        : standing
            ? Colors.blue
            : status.isOverdue
                ? Colors.red
                : Colors.orange;

    final label = paid
        ? 'Opłacone'
        : standing
            ? 'Przelew stały'
            : status.isOverdue
                ? 'Zaległość'
                : 'Do zapłaty';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  'Termin: ${status.dueDate}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.label, required this.row});

  final String label;
  final PaymentMonthStatusRow row;

  @override
  Widget build(BuildContext context) {
    final color = row.isPaid
        ? Colors.green
        : row.hasPending
            ? Colors.amber
            : row.isOverdue
                ? Colors.red
                : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
          Text(
            row.isPaid
                ? 'OK'
                : row.hasPending
                    ? 'Oczekuje'
                    : row.isOverdue
                        ? 'Zaległość'
                        : '—',
            style: GoogleFonts.outfit(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}
