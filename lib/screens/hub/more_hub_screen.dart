import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../ui/slavia_ui.dart';
import '../announcements_manage_screen.dart';
import '../athlete_list_screen.dart';
import '../athlete_portal_screen.dart';
import '../audit_log_screen.dart';
import '../calculators_page.dart';
import '../competition_assignment_screen.dart';
import '../profile_page.dart';
import '../sinclair_calculator_page.dart';
import '../proportions_calculator_page.dart';
import '../superadmin_athlete_manager_screen.dart';
import '../user_management_screen.dart';

/// Zakładka „Więcej” — kalkulatory, kadra, administracja, profil.
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final roles = auth.user?.roles ?? [];
    final isAthlete = roles.contains('Athlete');
    final isStaff = roles.any(
      (r) => r == 'Trainer' || r == 'Admin' || r == 'SuperAdmin',
    );
    final isClubAdmin =
        roles.contains('Admin') || roles.contains('SuperAdmin');
    final isSuper = roles.contains('SuperAdmin');
    final primary = Theme.of(context).colorScheme.primary;

    void push(Widget page) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
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
                  SlaviaUi.homeBadge(context, 'USTAWIENIA'),
                  const SizedBox(height: 10),
                  Text(
                    'Więcej',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kalkulatory, lista zawodników i opcje dla kadry.',
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
                SlaviaUi.hubTile(
                  context,
                  title: 'Profil i motyw',
                  subtitle: 'Konto, wygląd aplikacji',
                  icon: Icons.person_outline_rounded,
                  accent: primary,
                  onTap: () => push(const ProfilePage()),
                ),
                const SizedBox(height: 10),
                SlaviaUi.sectionHeader(
                  context,
                  'Kalkulatory',
                  accent: Colors.amber,
                  icon: Icons.calculate_outlined,
                ),
                SlaviaUi.hubTile(
                  context,
                  title: 'Sinclair',
                  subtitle: 'Współczynnik i porównanie wyników',
                  icon: Icons.calculate_rounded,
                  accent: Colors.amber,
                  onTap: () => push(const SinclairCalculatorPage()),
                ),
                const SizedBox(height: 10),
                SlaviaUi.hubTile(
                  context,
                  title: 'Proporcje bojów',
                  subtitle: 'Widełki i analiza relacji',
                  icon: Icons.balance_rounded,
                  accent: Colors.blue,
                  onTap: () => push(const ProportionsCalculatorPage()),
                ),
                const SizedBox(height: 10),
                SlaviaUi.hubTile(
                  context,
                  title: 'Wszystkie narzędzia',
                  subtitle: 'Pełna lista modułów wg roli',
                  icon: Icons.handyman_outlined,
                  accent: Colors.blueGrey,
                  onTap: () => push(const CalculatorsPage()),
                ),
                if (isAthlete) ...[
                  const SizedBox(height: 20),
                  SlaviaUi.sectionHeader(
                    context,
                    'Zawodnik',
                    accent: Colors.purple,
                    icon: Icons.stars_rounded,
                  ),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Mój panel',
                    subtitle: 'Wyniki i statystyki',
                    icon: Icons.bar_chart_rounded,
                    accent: Colors.purple,
                    onTap: () => push(const AthletePortalScreen()),
                  ),
                ],
                if (isStaff) ...[
                  const SizedBox(height: 20),
                  SlaviaUi.sectionHeader(
                    context,
                    'Kadra',
                    accent: Theme.of(context).colorScheme.secondary,
                    icon: Icons.groups_rounded,
                  ),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Lista zawodników',
                    subtitle: 'Profile i wykresy',
                    icon: Icons.groups_outlined,
                    accent: primary,
                    onTap: () => push(const AthleteListScreen()),
                  ),
                  const SizedBox(height: 10),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Przypisywanie startów',
                    subtitle: 'Zawody i składy',
                    icon: Icons.assignment_ind_rounded,
                    accent: Colors.cyan,
                    onTap: () => push(const CompetitionAssignmentScreen()),
                  ),
                ],
                if (isClubAdmin) ...[
                  const SizedBox(height: 20),
                  SlaviaUi.sectionHeader(
                    context,
                    'Administracja',
                    accent: Colors.red,
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Zarządzanie ogłoszeniami',
                    subtitle: 'Publikacja dla klubu',
                    icon: Icons.campaign_outlined,
                    accent: Colors.red,
                    onTap: () => push(const AnnouncementsManageScreen()),
                  ),
                  const SizedBox(height: 10),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Użytkownicy',
                    subtitle: 'Konta w systemie',
                    icon: Icons.manage_accounts_outlined,
                    accent: Colors.red,
                    onTap: () => push(const UserManagementScreen()),
                  ),
                ],
                if (isSuper) ...[
                  const SizedBox(height: 10),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Superadmin — zawodnicy',
                    subtitle: 'Zaawansowane zarządzanie',
                    icon: Icons.shield_outlined,
                    accent: Colors.deepPurple,
                    onTap: () => push(const SuperAdminAthleteManagerScreen()),
                  ),
                  const SizedBox(height: 10),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Dziennik audytu',
                    subtitle: 'Logi systemowe',
                    icon: Icons.history_rounded,
                    accent: Colors.deepPurple,
                    onTap: () => push(const AuditLogScreen()),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
