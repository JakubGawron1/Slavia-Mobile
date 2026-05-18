import 'package:flutter/material.dart';

import '../screens/dashboard_page.dart';
import '../screens/hub/club_hub_screen.dart';
import '../screens/hub/more_hub_screen.dart';
import '../screens/hub/training_hub_screen.dart';

/// Główne zakładki — 4 pozycje: Start, Treningi, Klub, Więcej.
enum MainTab {
  home,
  training,
  club,
  more,
}

extension MainTabX on MainTab {
  String get label => switch (this) {
        MainTab.home => 'Start',
        MainTab.training => 'Treningi',
        MainTab.club => 'Klub',
        MainTab.more => 'Więcej',
      };

  IconData get icon => switch (this) {
        MainTab.home => Icons.home_outlined,
        MainTab.training => Icons.fitness_center_outlined,
        MainTab.club => Icons.groups_outlined,
        MainTab.more => Icons.apps_outlined,
      };

  IconData get selectedIcon => switch (this) {
        MainTab.home => Icons.home_rounded,
        MainTab.training => Icons.fitness_center_rounded,
        MainTab.club => Icons.groups_rounded,
        MainTab.more => Icons.apps_rounded,
      };

  Widget get page => switch (this) {
        MainTab.home => const DashboardPage(),
        MainTab.training => const TrainingHubScreen(),
        MainTab.club => const ClubHubScreen(),
        MainTab.more => const MoreHubScreen(),
      };

  /// Indeks w [NavigationBar] — zachowane dla skrótów systemowych.
  static MainTab? fromLegacyShortcut(String type) => switch (type) {
        'shortcut_training' => MainTab.training,
        'shortcut_calendar' => MainTab.training,
        _ => null,
      };
}
