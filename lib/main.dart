import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/barbell_premium_service.dart';
import 'services/notification_timezone.dart';
import 'services/fcm_service.dart';
import 'services/push_notification_service.dart';
import 'services/secure_credentials_store.dart';
import 'routing/app_router.dart';
import 'models/auth.dart';
import 'services/panel_navigation_service.dart';
import 'utils/theme_preset_catalog.dart';
import 'utils/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL', null);
  await ensureLocalTimezoneInitialized();
  await ThemePresetCatalog.ensureLoaded();
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider(prefs);
  final apiService = ApiService();
  final panelNav = PanelNavigationService(apiService);
  final barbellPremium = BarbellPremiumService();
  themeProvider.attachApi(apiService);
  final token = await apiService.getToken();

  // Init push notifications early so the plugin registers
  await PushNotificationService().init(apiService);
  await FcmService.instance.init(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<PanelNavigationService>.value(value: panelNav),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, token)),
        ChangeNotifierProvider.value(value: barbellPremium),
        Provider<PushNotificationService>.value(
          value: PushNotificationService(),
        ),
      ],
      child: const AuthAppearanceSync(child: SlaviaApp()),
    ),
  );
}

class SlaviaApp extends StatefulWidget {
  const SlaviaApp({super.key});

  @override
  State<SlaviaApp> createState() => _SlaviaAppState();
}

class _SlaviaAppState extends State<SlaviaApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= createAppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, int>(
      selector: (_, tp) =>
          Object.hash(tp.themeMode, tp.preset, tp.outdoorCompetitionContrast),
      builder: (context, appearanceRev, child) {
        final themeProvider = context.read<ThemeProvider>();
        final auth = context.read<AuthProvider>();
        final router = _router ??= createAppRouter(auth);
        final loading = auth.isLoading && auth.user == null && auth.isAuthenticated;

        return MaterialApp.router(
          title: 'CKS Slavia',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(false),
          darkTheme: themeProvider.getTheme(true),
          themeMode: themeProvider.themeMode,
          routerConfig: router,
          builder: (context, child) {
            if (loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

/// Synchronizacja motywu z `/api/auth/me` — poza drzewem `MaterialApp`, żeby nie przebudowywać całej aplikacji.
class AuthAppearanceSync extends StatefulWidget {
  const AuthAppearanceSync({super.key, required this.child});

  final Widget child;

  @override
  State<AuthAppearanceSync> createState() => _AuthAppearanceSyncState();
}

class _AuthAppearanceSyncState extends State<AuthAppearanceSync> {
  String? _appearanceSig;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AuthUser?>((a) => a.user);
    if (user != null) {
      final sig =
          '${user.id}|${user.uiThemePreset ?? ''}|${user.uiColorMode ?? ''}';
      if (sig != _appearanceSig) {
        _appearanceSig = sig;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await context.read<ThemeProvider>().syncFromAuthUser(user);
        });
      }
    } else {
      _appearanceSig = null;
    }
    return widget.child;
  }
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  AuthUser? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  AuthProvider(this._apiService, String? token) {
    if (token != null) {
      _isAuthenticated = true;
      _loadUser();
    }
  }

  AuthUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> _loadUser() async {
    final cached = await _apiService.getCachedMe();
    if (cached != null) {
      _user = cached;
      notifyListeners();
    }
    try {
      _user = await _apiService.getMe();
      PushNotificationService().startPolling();
      notifyListeners();
    } catch (e) {
      if (_user == null) {
        logout();
      }
    }
  }

  Future<void> refreshMe() async {
    await _loadUser();
  }

  Future<void> login(
    String username,
    String password, {
    String? totpCode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.login(username, password, totpCode: totpCode);
      _isAuthenticated = true;
      await _loadUser();
      PushNotificationService().startPolling();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _apiService.setToken(null);
    PushNotificationService().stopPolling();
    PushNotificationService().clearSeenIds();
    unawaited(AppBadgePlus.updateBadge(0));
    await SecureCredentialsStore.instance.clearLoginCredentials();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
