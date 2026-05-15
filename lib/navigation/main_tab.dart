import 'package:flutter/material.dart';

import '../screens/announcement_page.dart';
import '../screens/athlete_list_screen.dart';
import '../screens/calculators_page.dart';
import '../screens/calendar_screen.dart';
import '../screens/dashboard_page.dart';

/// Główne zakładki aplikacji — jedna lista źródłem prawdy dla docka i [IndexedStack].
enum MainTab {
  home,
  athletes,
  tools,
  calendar,
  announcements,
}

extension MainTabX on MainTab {
  String get label => switch (this) {
        MainTab.home => 'Start',
        MainTab.athletes => 'Zawodnicy',
        MainTab.tools => 'Narzędzia',
        MainTab.calendar => 'Moje starty',
        MainTab.announcements => 'Ogłoszenia',
      };

  IconData get icon => switch (this) {
        MainTab.home => Icons.home_outlined,
        MainTab.athletes => Icons.groups_outlined,
        MainTab.tools => Icons.handyman_outlined,
        MainTab.calendar => Icons.event_available_outlined,
        MainTab.announcements => Icons.campaign_outlined,
      };

  IconData get selectedIcon => switch (this) {
        MainTab.home => Icons.home_rounded,
        MainTab.athletes => Icons.groups_rounded,
        MainTab.tools => Icons.handyman_rounded,
        MainTab.calendar => Icons.event_available_rounded,
        MainTab.announcements => Icons.campaign_rounded,
      };

  Widget get page => switch (this) {
        MainTab.home => const DashboardPage(),
        MainTab.athletes => const AthleteListScreen(),
        MainTab.tools => const CalculatorsPage(),
        MainTab.calendar => const CalendarScreen(),
        MainTab.announcements => const AnnouncementPage(),
      };
}
