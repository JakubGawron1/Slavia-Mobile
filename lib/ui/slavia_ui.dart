import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wspólny język wizualny z frontendem (Nuxt UI / sekcje strony głównej).
abstract final class SlaviaUi {
  SlaviaUi._();

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static Color _outline(BuildContext context, Color tint) {
    final a = Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10;
    return tint.withValues(alpha: a);
  }

  /// Karta / panel z obramowaniem i lekkim cieniem (jak `rounded-3xl` + ring na stronie).
  static BoxDecoration cardShell(
    BuildContext context, {
    Color? borderTint,
    double radius = radiusLg,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tint = borderTint ?? cs.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _outline(context, tint)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Nagłówek sekcji: uppercase, tracking (jak etykiety na `index.vue`).
  static Widget sectionHeader(
    BuildContext context,
    String title, {
    Color? accent,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final c = accent ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: c.withValues(alpha: 0.9)),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.35,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// „Pigułka” jak badge na stronie głównej (hero).
  static Widget homeBadge(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
        color: cs.primary.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.08,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration filledField(
    BuildContext context, {
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 22) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.35 : 0.65,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(
          color: cs.primary.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
    );
  }

  /// Pusty stan z ikoną w „bańce” (listy, dzienniki).
  static Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.09),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, size: 42, color: cs.primary.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.4,
                color: cs.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Karta KPI na dashboardzie — obramowanie z lekkim „światłem” akcentu.
  static const double minTouchTarget = 48;

  /// Duży przycisk akcji (min. 48 dp wysokości).
  static Widget primaryButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool filled = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: filled ? cs.onPrimary : cs.primary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: filled ? cs.onPrimary : cs.primary,
          ),
        ),
      ],
    );
    return SizedBox(
      width: double.infinity,
      height: minTouchTarget,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
              ),
              child: child,
            ),
    );
  }

  /// Kafelek menu hubu — duży obszar dotyku, spójna karta.
  static Widget hubTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusLg),
        child: Ink(
          decoration: cardShell(context, borderTint: accent, radius: radiusLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minTouchTarget + 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(radiusSm),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.3,
                            color: cs.onSurface.withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration statCardDecoration(BuildContext context, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusLg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.surface,
          cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
        ],
      ),
      border: Border.all(
        width: 1.5,
        color: Color.lerp(accent, cs.outline, 0.55)!,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
