import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/notification_timezone.dart';
import 'services/push_notification_service.dart';
import 'services/secure_credentials_store.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'models/auth.dart';
import 'utils/theme_provider.dart';
import 'widgets/biometric_gate.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL', null);
  await ensureLocalTimezoneInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider(prefs);
  final apiService = ApiService();
  themeProvider.attachApi(apiService);
  final token = await apiService.getToken();

  // Init push notifications early so the plugin registers
  await PushNotificationService().init(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, token)),
        Provider<PushNotificationService>.value(
          value: PushNotificationService(),
        ),
      ],
      child: const SlaviaApp(),
    ),
  );
}

class SlaviaApp extends StatefulWidget {
  const SlaviaApp({super.key});

  @override
  State<SlaviaApp> createState() => _SlaviaAppState();
}

class _SlaviaAppState extends State<SlaviaApp> {
  /// Unikamy wielokrotnego synchronizowania tego samego stanu konta.
  String? _appearanceSig;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;
    if (user != null) {
      final sig =
          '${user.id}|${user.uiThemePreset ?? ''}|${user.uiColorMode ?? ''}';
      if (sig != _appearanceSig) {
        _appearanceSig = sig;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await themeProvider.syncFromAuthUser(user);
        });
      }
    } else {
      _appearanceSig = null;
    }

    return MaterialApp(
      title: 'CKS Slavia',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getTheme(false),
      darkTheme: themeProvider.getTheme(true),
      themeMode: themeProvider.themeMode,
      home: auth.isAuthenticated
          ? const BiometricGate(child: MainScreen())
          : const LoginScreen(),
    );
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

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.login(username, password);
      _isAuthenticated = true;
      await _loadUser();
      // Start polling for system notifications after login
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
