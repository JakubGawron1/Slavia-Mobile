import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_brand.dart';
import '../main.dart';
import '../ui/slavia_ui.dart';
import '../screens/athlete_detail_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_page.dart';
import '../screens/recovery_journal_screen.dart';
import '../screens/athlete_achievements_screen.dart';
import '../screens/athlete_timeline_screen.dart';
import '../screens/club_posts_screen.dart';
import '../screens/club_gallery_screen.dart';
import 'main_tab.dart';

void _popDrawerThen(BuildContext drawerContext, void Function(NavigatorState nav) action) {
  final nav = Navigator.of(drawerContext);
  nav.pop();
  WidgetsBinding.instance.addPostFrameCallback((_) => action(nav));
}

/// Boczne menu: klub WWW, komunikacja, skróty zawodnika, przejścia do zakładek.
class SlaviaAppDrawer extends StatelessWidget {
  const SlaviaAppDrawer({
    super.key,
    required this.selectedTab,
    required this.onSelectTab,
  });

  final MainTab selectedTab;
  final ValueChanged<MainTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    const hPad = 12.0;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(SlaviaUi.radiusLg)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.18),
                    primary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CKS Slavia',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Menu i skróty',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
              child: SlaviaUi.sectionHeader(context, 'Aplikacja', accent: primary, icon: Icons.apps_rounded),
            ),
            ...MainTab.values.map((tab) {
              final selected = tab == selectedTab;
              return ListTile(
                leading: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  color: selected ? primary : cs.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  tab.label,
                  style: GoogleFonts.outfit(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? primary : cs.onSurface,
                  ),
                ),
                selected: selected,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(tab);
                },
              );
            }),
            const Divider(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              child: SlaviaUi.sectionHeader(context, 'Klub na WWW', accent: cs.tertiary, icon: Icons.public_rounded),
            ),
            if (AppBrand.hasPublicSite) ...[
              ListTile(
                leading: Icon(Icons.public_rounded, color: cs.primary),
                title: Text('Strona klubu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text(AppBrand.publicSiteLabel, style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final ok = await AppBrand.openPublicSite();
                    if (!ok && messenger != null && messenger.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Nie udało się otworzyć strony.', style: GoogleFonts.outfit())),
                      );
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.article_outlined, color: cs.primary),
                title: Text('Aktualności', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Wpisy z aplikacji (API)',
                  style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                onTap: () {
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(MaterialPageRoute<void>(builder: (_) => const ClubPostsScreen()));
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: cs.tertiary),
                title: Text('Galeria', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Zdjęcia z aplikacji (API)',
                  style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                onTap: () {
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(MaterialPageRoute<void>(builder: (_) => const ClubGalleryScreen()));
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.event_note_rounded, color: cs.primary),
                title: Text('Kalendarz klubu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                onTap: () {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final ok = await AppBrand.openClubPath('/kalendarz');
                    if (!ok && messenger != null && messenger.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Nie udało się otworzyć kalendarza.', style: GoogleFonts.outfit())),
                      );
                    }
                  });
                },
              ),
            ] else
              ListTile(
                leading: Icon(Icons.public_rounded, color: cs.outline),
                title: Text('Strona klubu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Ustaw przy buildzie: --dart-define=SLAVIA_WEB_URL=https://…',
                  style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55)),
                ),
              ),
            const Divider(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              child: SlaviaUi.sectionHeader(context, 'Kontakt', accent: cs.secondary, icon: Icons.forum_outlined),
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline_rounded, color: cs.secondary),
              title: Text('Czat trener–zawodnik', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Wiadomości 1:1',
                style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              onTap: () {
                _popDrawerThen(context, (nav) {
                  nav.push<void>(MaterialPageRoute<void>(builder: (_) => const ChatScreen()));
                });
              },
            ),
            if (auth.user?.athleteId != null && auth.user!.athleteId!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                child: SlaviaUi.sectionHeader(
                  context,
                  'Mój profil zawodnika',
                  accent: primary,
                  icon: Icons.person_search_rounded,
                ),
              ),
              ListTile(
                leading: Icon(Icons.insights_rounded, color: cs.secondary),
                title: Text('Wykresy i statystyki', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text('Jak na WWW', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55))),
                onTap: () {
                  final id = auth.user!.athleteId!;
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AthleteDetailScreen(athleteId: id, title: 'Mój profil'),
                      ),
                    );
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.timeline_rounded, color: cs.tertiary),
                title: Text('Oś czasu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Wyniki, obecność, dziennik treningów',
                  style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                onTap: () {
                  final id = auth.user!.athleteId!;
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AthleteTimelineScreen(
                          athleteId: id,
                          subtitle: 'Mój profil',
                        ),
                      ),
                    );
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.spa_outlined, color: cs.primary),
                title: Text('Dziennik regeneracji', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text('Sen i gotowość', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55))),
                onTap: () {
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(MaterialPageRoute<void>(builder: (_) => const RecoveryJournalScreen()));
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.military_tech_rounded, color: Colors.amber.shade700),
                title: Text('Osiągnięcia', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                subtitle: Text('Odznaki i poziomy', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55))),
                onTap: () {
                  _popDrawerThen(context, (nav) {
                    nav.push<void>(MaterialPageRoute<void>(builder: (_) => const AthleteAchievementsScreen()));
                  });
                },
              ),
            ],
            const Divider(height: 28),
            ListTile(
              leading: Icon(Icons.person_outline_rounded, color: cs.onSurface.withValues(alpha: 0.75)),
              title: Text('Profil i motyw', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              onTap: () {
                _popDrawerThen(context, (nav) {
                  nav.push<void>(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
