import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/slavia_ui.dart';

/// Tryb pokazowy bez API — targi, prezentacje (idea #137).
class DemoShellScreen extends StatelessWidget {
  const DemoShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Demonstracja',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Zamknij',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To są przykładowe dane — bez konta i bez połączenia z serwerem klubu.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _demoCard(
            context,
            icon: Icons.bolt_rounded,
            title: 'Aktywny',
            subtitle: 'Zawodnik',
          ),
          _demoCard(
            context,
            icon: Icons.campaign_outlined,
            title: 'Ogłoszenia',
            subtitle: '„Zbiórka na wyjazd” — przykład',
          ),
          _demoCard(
            context,
            icon: Icons.calendar_month_rounded,
            title: 'Moje starty',
            subtitle: '15 cze · Liga juniorów — Warszawa',
          ),
          const SizedBox(height: 20),
          Text(
            'Po zalogowaniu zobaczysz prawdziwe dane konta.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: cs.primary),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
