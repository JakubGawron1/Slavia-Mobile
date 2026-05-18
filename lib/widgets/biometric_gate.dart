import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opcjonalna blokada po powrocie z tła — Face ID / odcisk (idea #121).
const kBiometricUnlockPrefKey = 'slavia_biometric_unlock';

class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {

  DateTime? _pausedAt;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      _evaluateLock();
    }
  }

  Future<void> _evaluateLock() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(kBiometricUnlockPrefKey) ?? false)) return;
    final paused = _pausedAt;
    if (paused == null) return;
    // Krótkie przełączenia (np. powiadomienie) — bez blokady.
    if (DateTime.now().difference(paused) < const Duration(seconds: 8)) {
      _pausedAt = null;
      return;
    }
    final auth = LocalAuthentication();
    final supported = await auth.isDeviceSupported();
    final hasBiometrics = await auth.canCheckBiometrics;
    if ((!supported && !hasBiometrics) || !mounted) {
      _pausedAt = null;
      return;
    }
    setState(() => _locked = true);
    await _unlockInternal();
  }

  Future<void> _unlockInternal() async {
    final auth = LocalAuthentication();
    try {
      final ok = await auth.authenticate(
        localizedReason: 'Odblokuj aplikację CKS Slavia',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      if (!mounted) return;
      if (ok) {
        setState(() {
          _locked = false;
          _pausedAt = null;
        });
      } else {
        setState(() => _locked = true);
      }
    } catch (_) {
      if (mounted) setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        if (_locked)
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.65),
            dismissible: false,
          ),
        if (_locked)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Material(
                color: cs.surface,
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 48, color: cs.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Aplikacja zablokowana',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Użyj biometrii lub kodu urządzenia, aby kontynuować.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.35,
                          color: cs.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _unlockInternal,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Odblokuj'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
