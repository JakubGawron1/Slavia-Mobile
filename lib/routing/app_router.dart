import 'package:go_router/go_router.dart';

import '../main.dart' show AuthProvider;
import '../screens/banned_screen.dart';
import '../screens/browser_panel_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/notification_screen.dart';
import '../widgets/biometric_gate.dart';

/// Canonical paths for deep links (FCM, quick actions) — extend in Fala 3+.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const banned = '/banned';
  static const browserPanel = '/browser-panel';
  static const chat = '/chat';
  static const notifications = '/notifications';
}

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = auth.isAuthenticated;
      final loading = auth.isLoading && auth.user == null;

      if (!loggedIn) {
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }
      if (loading) return null;

      if (auth.user?.isBanned == true) {
        return loc == AppRoutes.banned ? null : AppRoutes.banned;
      }

      final roles = auth.user?.roles ?? [];
      final browserOnlyAdmin = (roles.contains('Admin') || roles.contains('SuperAdmin')) &&
          !roles.contains('Athlete') &&
          !roles.contains('Trainer');
      if (browserOnlyAdmin) {
        return loc == AppRoutes.browserPanel ? null : AppRoutes.browserPanel;
      }

      if (loc == AppRoutes.login ||
          loc == AppRoutes.banned ||
          loc == AppRoutes.browserPanel) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.banned,
        builder: (_, _) => BannedScreen(reason: auth.user?.bannedReason),
      ),
      GoRoute(
        path: AppRoutes.browserPanel,
        builder: (_, _) => const BrowserPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const BiometricGate(child: MainScreen()),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, _) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationScreen(),
      ),
    ],
  );
}
