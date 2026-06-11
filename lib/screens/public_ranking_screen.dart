import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/api_service_public_ext.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart' show friendlyNetworkError;

/// Publiczny ranking Sinclair — parity z `/zawodnicy` (Fala 4).
class PublicRankingScreen extends StatefulWidget {
  const PublicRankingScreen({super.key});

  @override
  State<PublicRankingScreen> createState() => _PublicRankingScreenState();
}

class _PublicRankingScreenState extends State<PublicRankingScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final api = Provider.of<ApiService>(context, listen: false);
    return api.getSinclairRanking();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking Sinclair')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
            final rows = snap.data ?? [];
            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Brak danych rankingu.')),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: rows.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlaviaUi.sectionHeader(
                        context,
                        'Elita Sinclair',
                        accent: cs.primary,
                        icon: Icons.leaderboard_rounded,
                      ),
                      Text(
                        'Ranking po współczynniku IWF 2025–2028 — jak na stronie klubu.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                final row = rows[index - 1];
                final rank = index;
                final name = row['full_name'] as String? ?? '—';
                final sinclair = row['sinclair_total'];
                final total = row['total_kg'];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                      child: Text(
                        '$rank',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      'Sinclair: ${sinclair ?? '—'} · Total: ${total ?? '—'} kg',
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
