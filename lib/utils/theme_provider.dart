import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SlaviaPreset { slavia, iron, arena, platform, midnight, ruby, neon, blackgym, pink }

class ThemeProvider with ChangeNotifier {
  SlaviaPreset _preset = SlaviaPreset.slavia;
  ThemeMode _themeMode = ThemeMode.dark;

  SlaviaPreset get preset => _preset;
  ThemeMode get themeMode => _themeMode;

  void setPreset(SlaviaPreset preset) {
    _preset = preset;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  ThemeData getTheme(bool isDark) {
    final colors = _getPresetColors(_preset, isDark);
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        onSurface: colors.onSurface,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: colors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.onSurface.withOpacity(0.05)),
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.onSurface),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.onSurface),
        bodyLarge: GoogleFonts.outfit(color: colors.onSurface.withOpacity(0.9)),
      ),
    );
  }

  _PresetColors _getPresetColors(SlaviaPreset preset, bool isDark) {
    switch (preset) {
      case SlaviaPreset.slavia:
        return isDark 
          ? _PresetColors(
              primary: const Color(0xFF00DC82),
              secondary: const Color(0xFF00A155),
              background: const Color(0xFF0F172A),
              surface: const Color(0xFF1E293B),
              card: const Color(0xFF1E293B),
              onSurface: Colors.white,
            )
          : _PresetColors(
              primary: const Color(0xFF00C16A),
              secondary: const Color(0xFF00A155),
              background: const Color(0xFFF8FAFF),
              surface: Colors.white,
              card: Colors.white,
              onSurface: const Color(0xFF0B1726),
            );
      case SlaviaPreset.iron:
        return _PresetColors(
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF0284C7),
          background: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FC),
          surface: isDark ? const Color(0xFF0F172A) : Colors.white,
          card: isDark ? const Color(0xFF0F172A) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF0C1528),
        );
      case SlaviaPreset.arena:
        return _PresetColors(
          primary: const Color(0xFFFBBF24),
          secondary: const Color(0xFFD97706),
          background: isDark ? const Color(0xFF120F0D) : const Color(0xFFFFFAF5),
          surface: isDark ? const Color(0xFF1C1410) : Colors.white,
          card: isDark ? const Color(0xFF1C1410) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF1F1612),
        );
      case SlaviaPreset.ruby:
        return _PresetColors(
          primary: const Color(0xFFEF4444),
          secondary: const Color(0xFFB91C1C),
          background: isDark ? const Color(0xFF1A0B0B) : const Color(0xFFFFF9F8),
          surface: isDark ? const Color(0xFF281212) : Colors.white,
          card: isDark ? const Color(0xFF281212) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF1C1010),
        );
      case SlaviaPreset.blackgym:
        return _PresetColors(
          primary: const Color(0xFF22C55E),
          secondary: const Color(0xFF16A34A),
          background: isDark ? Colors.black : const Color(0xFFF8FAFC),
          surface: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          card: isDark ? const Color(0xFF141414) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF020617),
        );
      default:
        return _PresetColors(
          primary: const Color(0xFF00DC82),
          secondary: const Color(0xFF00A155),
          background: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
          surface: isDark ? const Color(0xFF1E293B) : Colors.white,
          card: isDark ? const Color(0xFF1E293B) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF0B1726),
        );
    }
  }
}

class _PresetColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color onSurface;

  _PresetColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.onSurface,
  });
}
