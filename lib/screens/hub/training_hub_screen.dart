import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/panel_navigation_service.dart';
import '../../ui/slavia_ui.dart';
import '../../utils/panel_navigation_catalog.dart';
import '../athlete_training_plans_screen.dart';
import '../attendance_qr_scan_screen.dart';
import '../barbell_analysis_screen.dart';
import '../calendar_screen.dart';
import '../recovery_journal_screen.dart';
import '../training_log_screen.dart';
import '../ai_coach_screen.dart';
import '../membership_payments_screen.dart';
import '../trainer_training_plans_screen.dart';

/// Zakładka „Treningi” — najczęstsze akcje zawodnika i kadry.
class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PanelNavigationService>(
      builder: (context, panelNav, _) {
        final auth = Provider.of<AuthProvider>(context);
        final roles = auth.user?.roles ?? [];
        final isAthlete = roles.contains('Athlete');
        final athleteId = auth.user?.athleteId ?? '';
        final canTrainerPlans = roles.contains('Trainer') ||
            roles.contains('Admin') ||
            roles.contains('SuperAdmin');
        final primary = Theme.of(context).colorScheme.primary;
        bool on(String flag) => panelNav.isModuleEnabled(flag);

        void push(Widget page) {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => page),
          );
        }

        final athleteTiles = <Widget>[];
        void addAthleteTile(Widget tile) {
          if (athleteTiles.isNotEmpty) {
            athleteTiles.add(const SizedBox(height: 10));
          }
          athleteTiles.add(tile);
        }

        if (on(PanelNavigationCatalog.athleteDziennik)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Dziennik treningów',
              subtitle: 'Zapisz dzisiejszy trening i śledź serię dni',
              icon: Icons.book_outlined,
              accent: Colors.teal,
              onTap: () => push(const TrainingLogScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteAnalizaSztangi)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Analiza sztangi',
              subtitle: 'Tor ruchu i wskazówki — pełna analiza w przeglądarce',
              icon: Icons.show_chart_rounded,
              accent: Colors.deepOrange,
              onTap: () => push(const BarbellAnalysisScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteObecnosc)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Skaner obecności',
              subtitle: 'Zeskanuj kod QR w sali treningowej',
              icon: Icons.qr_code_scanner_rounded,
              accent: primary,
              onTap: () => push(const AttendanceQrScanScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athletePlany)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Plany treningowe',
              subtitle: 'Plany od trenera',
              icon: Icons.calendar_view_week_rounded,
              accent: Colors.orange,
              onTap: () => push(const AthleteTrainingPlansScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteSkladki)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Składka klubowa',
              subtitle: 'Status wpłat i zgłoszenie przelewu',
              icon: Icons.payments_outlined,
              accent: Colors.green,
              onTap: () => push(const MembershipPaymentsScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteRegeneracja)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Dziennik regeneracji',
              subtitle: 'Sen i samopoczucie',
              icon: Icons.spa_outlined,
              accent: Colors.indigo,
              onTap: () => push(const RecoveryJournalScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteKalendarz)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Moje starty',
              subtitle: 'Kalendarz zawodów i przypisania',
              icon: Icons.event_available_rounded,
              accent: Colors.cyan,
              onTap: () => push(const CalendarScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.athleteTrenerAi)) {
          addAthleteTile(
            SlaviaUi.hubTile(
              context,
              title: 'Trener AI',
              subtitle: 'Plan, suplementacja i regeneracja',
              icon: Icons.smart_toy_outlined,
              accent: Colors.purple,
              onTap: () => push(
                const AiCoachScreen(isTrainerView: false),
              ),
            ),
          );
        }

        final trainerTiles = <Widget>[];
        void addTrainerTile(Widget tile) {
          if (trainerTiles.isNotEmpty) {
            trainerTiles.add(const SizedBox(height: 10));
          }
          trainerTiles.add(tile);
        }

        if (on(PanelNavigationCatalog.trainerPlany)) {
          addTrainerTile(
            SlaviaUi.hubTile(
              context,
              title: 'Plany treningowe',
              subtitle: 'Twórz i przypisuj plany zawodnikom',
              icon: Icons.edit_calendar_rounded,
              accent: Colors.orange,
              onTap: () => push(const TrainerTrainingPlansScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.trainerAnalizaSztangi)) {
          addTrainerTile(
            SlaviaUi.hubTile(
              context,
              title: 'Analiza sztangi',
              subtitle: 'Narzędzie techniczne (przeglądarka)',
              icon: Icons.show_chart_rounded,
              accent: Colors.deepOrange,
              onTap: () => push(const BarbellAnalysisScreen()),
            ),
          );
        }
        if (on(PanelNavigationCatalog.trainerTrenerAi)) {
          addTrainerTile(
            SlaviaUi.hubTile(
              context,
              title: 'Trener AI (kadra)',
              subtitle: 'Asystent dla trenera — plany i regeneracja',
              icon: Icons.smart_toy_outlined,
              accent: Colors.purple,
              onTap: () => push(
                const AiCoachScreen(isTrainerView: true),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlaviaUi.homeBadge(context, 'TWOJE TRENINGI'),
                      const SizedBox(height: 10),
                      Text(
                        'Treningi',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dziennik, plany, obecność i analiza techniki — w jednym miejscu.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.4,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isAthlete && athleteId.isNotEmpty && athleteTiles.isNotEmpty) ...[
                      SlaviaUi.sectionHeader(
                        context,
                        'Na co dzień',
                        accent: primary,
                        icon: Icons.fitness_center_rounded,
                      ),
                      ...athleteTiles,
                      const SizedBox(height: 20),
                    ],
                    if (canTrainerPlans && trainerTiles.isNotEmpty) ...[
                      SlaviaUi.sectionHeader(
                        context,
                        'Dla trenera',
                        accent: Theme.of(context).colorScheme.secondary,
                        icon: Icons.sports_rounded,
                      ),
                      ...trainerTiles,
                    ],
                    if (!isAthlete && !canTrainerPlans)
                      SlaviaUi.emptyState(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Brak modułów treningowych',
                        subtitle: 'Ta sekcja jest dostępna dla zawodników i trenerów.',
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
