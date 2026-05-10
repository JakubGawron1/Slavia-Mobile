import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'models/auth.dart';
import 'utils/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL', null);
  final apiService = ApiService();
  final token = await apiService.getToken();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, token)),
      ],
      child: const SlaviaApp(),
    ),
  );
}

class SlaviaApp extends StatelessWidget {
  const SlaviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CKS Slavia',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getTheme(false),
      darkTheme: themeProvider.getTheme(true),
      themeMode: themeProvider.themeMode,
      home: auth.isAuthenticated ? const MainScreen() : const LoginScreen(),
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
    try {
      _user = await _apiService.getMe();
      notifyListeners();
    } catch (e) {
      logout();
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _apiService.setToken(null);
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
