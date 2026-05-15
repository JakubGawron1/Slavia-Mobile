import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart';
import '../widgets/biometric_gate.dart';
import 'demo_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onBg = cs.onSurface;
    final muted = onBg.withValues(alpha: 0.62);

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: isDark ? 0.14 : 0.10),
                  cs.surface,
                  cs.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            right: -40,
            top: 80,
            child: Icon(
              Icons.sports_gymnastics,
              size: 140,
              color: cs.primary.withValues(alpha: 0.06),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: SlaviaUi.homeBadge(
                          context,
                          'CKS Slavia Ruda Śląska',
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Witaj w aplikacji',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.05,
                          color: onBg,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Zaloguj się — te same dane co na stronie klubu.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          height: 1.35,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: SlaviaUi.cardShell(
                          context,
                          borderTint: cs.primary,
                          radius: SlaviaUi.radiusXl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: GoogleFonts.outfit(fontSize: 16),
                              decoration: SlaviaUi.filledField(
                                context,
                                label: 'Użytkownik',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _tryLogin(context, auth),
                              style: GoogleFonts.outfit(fontSize: 16),
                              decoration: SlaviaUi.filledField(
                                context,
                                label: 'Hasło',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Pokaż' : 'Ukryj',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => _tryLogin(context, auth),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          SlaviaUi.radiusMd,
                                        ),
                                      ),
                                      backgroundColor: cs.primary,
                                      foregroundColor: cs.onPrimary,
                                    ),
                                    child: auth.isLoading
                                        ? SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                        : Text(
                                            'Zaloguj się',
                                            style: GoogleFonts.outfit(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildBiometricButton(context, auth),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const DemoShellScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(
                          'Tryb demonstracyjny',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Treningi · wyniki · kalendarz — w jednym miejscu.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton(BuildContext context, AuthProvider auth) {
    return FutureBuilder<bool>(
      future: _shouldShowBiometric(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
          ),
          child: IconButton(
            icon: const Icon(Icons.fingerprint_rounded),
            color: Theme.of(context).colorScheme.primary,
            iconSize: 32,
            padding: const EdgeInsets.all(12),
            onPressed: () => _tryBiometricLogin(context, auth),
          ),
        );
      },
    );
  }

  Future<bool> _shouldShowBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(kBiometricUnlockPrefKey) ?? false)) return false;
    final savedUser = prefs.getString('saved_username');
    final savedPass = prefs.getString('saved_password');
    return savedUser != null && savedPass != null;
  }

  Future<void> _tryBiometricLogin(BuildContext context, AuthProvider auth) async {
    final la = LocalAuthentication();
    final ok = await la.authenticate(
      localizedReason: 'Zaloguj się do CKS Slavia',
      options: const AuthenticationOptions(stickyAuth: true),
    );
    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('saved_username');
    final p = prefs.getString('saved_password');
    if (u != null && p != null) {
      _usernameController.text = u;
      _passwordController.text = p;
      await _tryLogin(context, auth);
    }
  }

  Future<void> _tryLogin(BuildContext context, AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    final u = _usernameController.text.trim();
    final p = _passwordController.text;
    try {
      await auth.login(u, p);
      // Save credentials for next biometric login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', u);
      await prefs.setString('saved_password', p);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Błąd logowania: ${friendlyNetworkError(e)}',
              style: GoogleFonts.outfit(),
            ),
          ),
        );
      }
    }
  }
}
