import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/competition.dart';
import '../services/api_service.dart';
import '../services/app_shortcuts_service.dart';
import '../services/app_update_service.dart';
import '../services/push_notification_service.dart';
import '../utils/app_shortcuts_bridge.dart';
import '../navigation/app_drawer.dart';
import '../navigation/main_tab.dart';
import 'profile_page.dart';
import 'notification_screen.dart';
import 'chat_screen.dart';
import 'training_log_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppShortcutsService.instance.ensureInitialized();
      if (!mounted) return;
      unawaited(_syncAthleteShortcutCalendarHint());
      final pending = AppShortcutsBridge.takePending();
      if (!mounted) return;
      if (pending == 'shortcut_chat') {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
        );
      } else if (pending == 'shortcut_training') {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final roles = auth.user?.roles ?? [];
        if (roles.contains('Athlete')) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const TrainingLogScreen(),
            ),
          );
        } else {
          setState(() => _currentIndex = MainTab.training.index);
        }
      } else if (pending == 'shortcut_calendar') {
        setState(() => _currentIndex = MainTab.training.index);
      }
      if (!mounted) return;
      unawaited(PushNotificationService().refreshBadgeFromApi());
      if (!mounted) return;
      AppUpdateService.instance.checkAndOfferUpdate(context);
    });
  }

  Future<void> _syncAthleteShortcutCalendarHint() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final roles = auth.user?.roles ?? [];
    if (!roles.contains('Athlete')) {
      await AppShortcutsService.instance.updateCalendarShortcutSubtitle(null);
      return;
    }
    try {
      final items = await api.getMyCalendarCompetitions();
      if (!mounted) return;
      if (items.isEmpty) {
        await AppShortcutsService.instance.updateCalendarShortcutSubtitle(
          'Brak przypisanych startów',
        );
        return;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      Competition? upcoming;
      for (final c in items) {
        final day = DateTime(c.date.year, c.date.month, c.date.day);
        if (!day.isBefore(today)) {
          if (upcoming == null || c.date.isBefore(upcoming.date)) {
            upcoming = c;
          }
        }
      }
      final sorted = List<Competition>.from(items)
        ..sort((a, b) => a.date.compareTo(b.date));
      final chosen = upcoming ?? sorted.last;
      final prefix = upcoming == null ? 'Ostatni: ' : '';
      var line =
          '$prefix${DateFormat('d MMM', 'pl_PL').format(chosen.date)} · ${chosen.title}';
      if (line.length > 48) {
        line = '${line.substring(0, 45)}…';
      }
      final loc = chosen.location.trim();
      if (loc.isNotEmpty) {
        final short =
            loc.length > 16 ? '${loc.substring(0, 13)}…' : loc;
        line = '$line · $short';
        if (line.length > 52) {
          line = '${line.substring(0, 49)}…';
        }
      }
      await AppShortcutsService.instance.updateCalendarShortcutSubtitle(line);
    } catch (_) {
      await AppShortcutsService.instance.updateCalendarShortcutSubtitle(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
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
      key: _shellKey,
      drawer: SlaviaAppDrawer(
        selectedTab: MainTab.values[_currentIndex],
        onSelectTab: (t) => setState(() => _currentIndex = t.index),
      ),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Menu',
                    style: IconButton.styleFrom(
                      backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                    ),
                    onPressed: () => _shellKey.currentState?.openDrawer(),
                    icon: Icon(
                      Icons.menu_rounded,
                      color: cs.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.7)],
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CKS Slavia',
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          MainTab.values[_currentIndex].label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _AppBarIconBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ChatScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  _AppBarIconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage(),
                      ),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        image: profileImg != null
                            ? DecorationImage(
                                image: NetworkImage(profileImg),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: primary.withValues(alpha: 0.1),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: IndexedStack(
                index: _currentIndex,
                sizing: StackFit.expand,
                children: [
                  for (final t in MainTab.values) t.page,
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: primary.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final bold = states.contains(WidgetState.selected);
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
          },
          destinations: [
            for (final t in MainTab.values)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
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
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: cs.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
