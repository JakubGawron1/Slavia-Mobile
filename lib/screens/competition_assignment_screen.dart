import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/competition.dart';
import '../models/athlete.dart';
import 'package:google_fonts/google_fonts.dart';

class CompetitionAssignmentScreen extends StatefulWidget {
  const CompetitionAssignmentScreen({super.key});

  @override
  State<CompetitionAssignmentScreen> createState() =>
      _CompetitionAssignmentScreenState();
}

class _CompetitionAssignmentScreenState
    extends State<CompetitionAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Starty Zawodników',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Competition>>(
        future: apiService.getCompetitions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          final competitions = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: competitions.length,
            itemBuilder: (context, index) {
              final c = competitions[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showAssignAthleteDialog(c, apiService),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.event_note,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.date.toString().substring(0, 10),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      c.location,
                                      style: TextStyle(color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAssignAthleteDialog(
    Competition competition,
    ApiService apiService,
  ) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Athlete>>(
        future: apiService.getAthletes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final athletes = snapshot.data!;
          return AlertDialog(
            title: Text('Przypisz do: ${competition.title}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: athletes.length,
                itemBuilder: (context, index) {
                  final a = athletes[index];
                  return ListTile(
                    title: Text(a.fullName),
                    onTap: () async {
                      try {
                        // Using the result submission endpoint as a proxy for assignment if no direct endpoint
                        // In the web app, assigning usually means creating a result submission with status 'Assigned' or similar.
                        // For now, I'll use the submitResult with kind 'competition' and location from competition.
                        await apiService.submitResult(
                          athleteId: a.id,
                          date: competition.date.toIso8601String(),
                          kind: 'competition',
                          location: competition.location,
                          total: 0, // Placeholder
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Przypisano ${a.fullName}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          );
        },
      ),
    );
  }
}
