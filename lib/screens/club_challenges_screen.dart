import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/api_service_public_ext.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart' show friendlyNetworkError;

/// Wyzwania klubu — parity z `/klub/wyzwania` (Fala 4).
class ClubChallengesScreen extends StatefulWidget {
  const ClubChallengesScreen({super.key});

  @override
  State<ClubChallengesScreen> createState() => _ClubChallengesScreenState();
}

class _ClubChallengesScreenState extends State<ClubChallengesScreen> {
  String _metric = 'sessions';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    final api = Provider.of<ApiService>(context, listen: false);
    return api.getMonthlyChallengeLeaderboard(metric: _metric);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _setMetric(String metric) {
    if (_metric == metric) return;
    setState(() {
      _metric = metric;
      _future = _load();
    });
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is num && _metric == 'tonnage') {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyzwania klubu'),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sessions', label: Text('Wpisy')),
                ButtonSegment(value: 'tonnage', label: Text('Tonaż')),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => _setMetric(s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(friendlyNetworkError(snap.error!)),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _refresh,
                                child: const Text('Spróbuj ponownie'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final data = snap.data ?? {};
                  final month = data['month'] as String? ?? '';
                  final leaderboard =
                      (data['leaderboard'] as List<dynamic>?) ?? [];
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: leaderboard.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SlaviaUi.sectionHeader(
                              context,
                              'Ranking miesiąca',
                              accent: cs.primary,
                              icon: Icons.emoji_events_outlined,
                            ),
                            if (month.isNotEmpty)
                              Text(
                                month,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.58),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }
                      final rank = index;
                      final row =
                          leaderboard[index - 1] as Map<String, dynamic>;
                      final name = row['full_name'] as String? ?? '—';
                      final value = _metric == 'tonnage'
                          ? row['tonnage_kg']
                          : row['session_count'];
                      final label = _metric == 'tonnage'
                          ? 'Tonaż: ${_formatValue(value)} kg'
                          : 'Wpisy: ${_formatValue(value)}';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                cs.primary.withValues(alpha: 0.12),
                            child: Text(
                              '$rank',
                              style:
                                  GoogleFonts.outfit(fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(label),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
