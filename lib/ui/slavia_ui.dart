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
}
