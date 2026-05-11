import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../models/competition.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kalendarz startów **tylko dla zalogowanego zawodnika** — zawody z przypisania (`/api/athletes/my-calendar`).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  bool _isAthlete(AuthProvider auth) {
    final r = auth.user?.roles ?? [];
    return r.contains('Athlete');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;

    if (!_isAthlete(auth)) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(
            'Moje starty',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined, size: 56, color: cs.outline),
                const SizedBox(height: 16),
                Text(
                  'Widok Twoich startów',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lista pokazuje zawody przypisane do profilu zawodnika. Dostępna jest dla kont z rolą Zawodnik.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Moje starty',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Competition>>(
        future: apiService.getMyCalendarCompetitions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            final friendly = msg.contains('calendar_athlete_only')
                ? 'Brak uprawnień do kalendarza zawodnika.'
                : 'Błąd: $msg';
            return Center(child: Text(friendly));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Brak przypisanych startów.\nTrener dopisze Cię do zawodów w panelu klubu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.45,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }

          items.sort((a, b) => a.date.compareTo(b.date));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final c = items[index];
              final isFirstInMonth =
                  index == 0 || items[index - 1].date.month != c.date.month;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFirstInMonth) _buildMonthHeader(context, c.date),
                  _buildEventCard(context, c),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    final monthName = DateFormat('MMMM yyyy', 'pl_PL').format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 4),
      child: Text(
        monthName.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Competition c) {
    final color = _getCategoryColor(c.category);
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 70,
                color: color.withValues(alpha: 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(c.date),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      DateFormat('EEE', 'pl_PL').format(c.date).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (c.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.category!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          const Spacer(),
                          if (c.status != null)
                            Text(
                              c.status!,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.location,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.blue;
    final cat = category.toLowerCase();
    if (cat.contains('mistrzostwa')) return Colors.orange;
    if (cat.contains('liga')) return Colors.green;
    if (cat.contains('klubowe')) return Colors.purple;
    return Colors.blue;
  }
}
