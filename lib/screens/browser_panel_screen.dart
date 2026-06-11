import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../ui/slavia_ui.dart';

/// Konto Admin/SuperAdmin bez roli zawodnik/trener — panel tylko w przeglądarce (MOB-DEPREC3).
class BrowserPanelScreen extends StatelessWidget {
  const BrowserPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.laptop_mac_rounded, size: 72, color: primary),
              const SizedBox(height: 20),
              Text(
                'Panel administracyjny w przeglądarce',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aplikacja mobilna Slavia obsługuje zawodnika i trenera. Zarządzanie klubem (CMS, import, audyt, konta adminów) jest dostępne w panelu WWW po zalogowaniu w przeglądarce.',
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
              const Spacer(),
              SlaviaUi.primaryButton(
                context,
                label: 'Wyloguj',
                icon: Icons.logout_rounded,
                onPressed: auth.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
