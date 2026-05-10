import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'dashboard_page.dart';
import 'announcement_page.dart';
import 'profile_page.dart';
import 'notification_screen.dart';
import 'athlete_list_screen.dart';
import 'calendar_screen.dart';
import 'calculators_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AthleteListScreen(),
    const CalculatorsPage(),
    const CalendarScreen(),
    const AnnouncementPage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Start'),
    _NavItem(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center, label: 'Zawodnicy'),
    _NavItem(icon: Icons.calculate_outlined, selectedIcon: Icons.calculate, label: 'Narzędzia'),
    _NavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Kalendarz'),
    _NavItem(icon: Icons.campaign_outlined, selectedIcon: Icons.campaign, label: 'Ogłoszenia'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;
    final profileImg = user?.avatarUrl ?? user?.athleteImageUrl;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.15),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
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
                      child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
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
                  // Notifications
                  _AppBarIconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  ),
                  const SizedBox(width: 4),
                  // Avatar / profile
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary.withOpacity(0.4), width: 2),
                        image: profileImg != null
                            ? DecorationImage(image: NetworkImage(profileImg), fit: BoxFit.cover)
                            : null,
                        color: primary.withOpacity(0.1),
                      ),
                      child: profileImg == null
                          ? Center(
                              child: Text(
                                (user?.username?.substring(0, 1) ?? '?').toUpperCase(),
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
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.15),
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
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
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
      onTap: onTap,
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
                color: isSelected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
      ),
    );
  }
}
