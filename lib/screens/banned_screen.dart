import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../ui/slavia_ui.dart';

/// Ekran po zbanowaniu konta — parity z WWW `/banned`.
class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key, this.reason, this.onLogout});

  final String? reason;
  final VoidCallback? onLogout;

  void _logout(BuildContext context) {
    if (onLogout != null) {
      onLogout!();
      return;
    }
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.shield_outlined, size: 72, color: primary),
              const SizedBox(height: 20),
              Text(
                'Konto zbanowane',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dostęp do aplikacji został ograniczony przez kadrę klubu — np. z powodu zaległości ze składką lub innych ustaleń wewnętrznych.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.45,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),
              if (reason != null && reason!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
                    ),
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    reason!.trim(),
                    style: GoogleFonts.outfit(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Skontaktuj się z trenerem lub administratorem klubu, aby wyjaśnić sytuację. Pełny panel administracyjny jest dostępny w przeglądarce.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              SlaviaUi.primaryButton(
                context,
                label: 'Wyloguj',
                icon: Icons.logout_rounded,
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
