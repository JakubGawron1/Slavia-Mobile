import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'sinclair_calculator_page.dart';
import 'proportions_calculator_page.dart';
import 'training_log_screen.dart';
import 'audit_log_screen.dart';
import 'user_management_screen.dart';
import 'athlete_portal_screen.dart';
import 'superadmin_athlete_manager_screen.dart';
import 'competition_assignment_screen.dart';
import 'announcements_manage_screen.dart';

class CalculatorsPage extends StatelessWidget {
  const CalculatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final roles = auth.user?.roles ?? [];
    /// Starty / zawody — kadra i administracja (jak wcześniej w aplikacji).
    final canStaffStarts = roles.contains('Trainer') ||
        roles.contains('Admin') ||
        roles.contains('SuperAdmin');
    final isClubAdmin =
        roles.contains('Admin') || roles.contains('SuperAdmin');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Narzędzia',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kalkulatory są dostępne dla każdego; reszta wg Twojej roli w klubie.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Athlete section
          if (roles.contains('Athlete')) ...[
            _sectionHeader(
              'Strefa Zawodnika',
              Icons.stars_rounded,
              Colors.purple,
            ),
            _toolCard(
              context,
              'Mój Panel Zawodnika',
              'Twoje wyniki, statystyki i zgłoszenia.',
              Icons.bar_chart_rounded,
              Colors.purple,
              const AthletePortalScreen(),
            ),
            _toolCard(
              context,
              'Dziennik treningów',
              'Twoje notatki i historia treningowa.',
              Icons.book_outlined,
              Colors.teal,
              const TrainingLogScreen(),
            ),
          ],

          // Calculators section
          _sectionHeader('Kalkulatory', Icons.calculate_rounded, Colors.amber),
          _toolCard(
            context,
            'Kalkulator Sinclair',
            'Przelicznik punktowy IWF 2025–2028.',
            Icons.calculate_rounded,
            Colors.amber,
            const SinclairCalculatorPage(),
          ),
          _toolCard(
            context,
            'Złote proporcje',
            'Widełki i analiza relacji — jak na stronie klubu.',
            Icons.balance_rounded,
            Colors.blue,
            const ProportionsCalculatorPage(),
          ),

          if (canStaffStarts) ...[
            _sectionHeader(
              'Trener i administracja',
              Icons.fitness_center_rounded,
              Colors.orange,
            ),
            _toolCard(
              context,
              'Uzupełnianie startów',
              'Przypisywanie zawodników do zawodów.',
              Icons.assignment_ind_rounded,
              Colors.cyan,
              const CompetitionAssignmentScreen(),
            ),
          ],

          // Administracja klubu — API wymaga Admin lub SuperAdmin
          if (isClubAdmin) ...[
            _sectionHeader(
              'Administracja klubu',
              Icons.admin_panel_settings_rounded,
              Colors.deepOrange,
            ),
            _toolCard(
              context,
              'Zarządzanie ogłoszeniami',
              'Tworzenie, szkice, publikacja — jak w panelu WWW.',
              Icons.campaign_rounded,
              Colors.orange,
              const AnnouncementsManageScreen(),
            ),
          ],

          // SuperAdmin tools
          if (roles.contains('SuperAdmin')) ...[
            _sectionHeader(
              'SuperAdministracja',
              Icons.security_rounded,
              Colors.red,
            ),
            _toolCard(
              context,
              'Zarządzanie kadrą',
              'Lista kont systemowych i uprawnień.',
              Icons.supervisor_account_rounded,
              Colors.red,
              const UserManagementScreen(),
            ),
            _toolCard(
              context,
              'Zarządzanie zawodnikami',
              'Baza zawodników klubu i ich dane.',
              Icons.people_rounded,
              Colors.deepOrange,
              const SuperAdminAthleteManagerScreen(),
            ),
            _toolCard(
              context,
              'Logi systemowe',
              'Historia zmian i audyt operacji.',
              Icons.history_rounded,
              Colors.deepPurple,
              const AuditLogScreen(),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      sliver: SliverToBoxAdapter(
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_right, color: color, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
