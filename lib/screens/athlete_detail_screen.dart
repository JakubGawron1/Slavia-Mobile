import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../widgets/athlete_overview_tab.dart';

/// Pełny profil zawodnika z wykresami i statystykami (jak `/athlete/[slug]` na WWW).
class AthleteDetailScreen extends StatelessWidget {
  final String athleteId;
  final String? title;

  const AthleteDetailScreen({super.key, required this.athleteId, this.title});

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title ?? 'Profil zawodnika',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: AthleteOverviewTab(
        athleteId: athleteId,
        api: api,
        canViewTraining: canViewAthleteTrainingData(athleteId, auth),
      ),
    );
  }
}
