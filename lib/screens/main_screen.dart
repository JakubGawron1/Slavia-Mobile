import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../config/app_brand.dart';
import '../services/app_update_service.dart';
import '../ui/slavia_ui.dart';
import 'dashboard_page.dart';
import 'announcement_page.dart';
import 'profile_page.dart';
import 'notification_screen.dart';
import 'athlete_detail_screen.dart';
import 'athlete_list_screen.dart';
import 'calendar_screen.dart';
import 'calculators_page.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppUpdateService.instance.checkAndOfferUpdate(context);
    });
  }

  final List<Widget> _pages = [
    const DashboardPage(),
    const AthleteListScreen(),
    const CalculatorsPage(),
    const CalendarScreen(),
    const AnnouncementPage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Start',
    ),
    _NavItem(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      label: 'Zawodnicy',
    ),
    _NavItem(
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate,
      label: 'Narzędzia',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Kalendarz',
    ),
    _NavItem(
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
      label: 'Ogłoszenia',
    ),
  ];

  Future<void> _openMoreMenu(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SlaviaUi.radiusXl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CKS Slavia',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Skróty w stylu strony klubu',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (AppBrand.hasPublicSite)
                ListTile(
                  leading: Icon(Icons.public_rounded, color: cs.primary),
                  title: Text(
                    'Strona klubu',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    AppBrand.publicSiteLabel,
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await AppBrand.openPublicSite();
                    if (context.mounted && !ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Nie udało się otworzyć strony.',
                            style: GoogleFonts.outfit(),
                          ),
                        ),
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.public_rounded, color: cs.outline),
                  title: Text(
                    'Strona klubu',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Ustaw przy buildzie: --dart-define=SLAVIA_WEB_URL=https://…',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: cs.secondary,
                ),
                title: Text(
                  'Czat trener–zawodnik',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Wiadomości 1:1',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
                  );
                },
              ),
              if (auth.user?.athleteId != null &&
                  auth.user!.athleteId!.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.insights_rounded, color: cs.secondary),
                  title: Text(
                    'Moje wykresy i statystyki',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Pełna analityka jak na WWW',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  onTap: () {
                    final id = auth.user!.athleteId!;
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AthleteDetailScreen(
                          athleteId: id,
                          title: 'Mój profil',
                        ),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.emoji_events_outlined, color: cs.tertiary),
                title: Text(
                  'Zawodnicy i wyniki',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Lista kadry',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: Icon(Icons.calculate_outlined, color: cs.secondary),
                title: Text(
                  'Kalkulatory i narzędzia',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month_outlined, color: cs.primary),
                title: Text(
                  'Kalendarz startów',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 3);
                },
              ),
              ListTile(
                leading: Icon(Icons.campaign_outlined, color: cs.primary),
                title: Text(
                  'Ogłoszenia',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 4);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.person_outline_rounded,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
                title: Text(
                  'Profil i motyw',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;
    final profileImg = user?.avatarUrl ?? user?.athleteImageUrl;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.15),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Więcej',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    onPressed: () => _openMoreMenu(context),
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Logo + title
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CKS Slavia',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  _AppBarIconBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ChatScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Notifications
                  _AppBarIconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Avatar / profile
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withOpacity(0.4),
                          width: 2,
                        ),
                        image: profileImg != null
                            ? DecorationImage(
                                image: NetworkImage(profileImg),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: primary.withOpacity(0.1),
                      ),
                      child: profileImg == null
                          ? Center(
                              child: Text(
                                (user == null || user.username.isEmpty
                                        ? '?'
                                        : user.username.substring(0, 1))
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.15),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = i == _currentIndex;
                return _NavButton(
                  item: item,
                  isSelected: isSelected,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Color primary;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}
