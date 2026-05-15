import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth.dart';
import '../services/api_service.dart';

/// Id presetów — zgodne z backendem i `SLAVIA_THEME_PRESETS` na WWW.
enum SlaviaPreset {
  pink,
  dark,
  slavia,
  iron,
  arena,
  platform,
  midnight,
  ruby,
  neon,
  blackgym,
}

/// Metadane jak na stronie (`useSlaviaAppearance.ts`).
abstract final class SlaviaAppearanceLabels {
  SlaviaAppearanceLabels._();

  static String title(SlaviaPreset p) => switch (p) {
        SlaviaPreset.pink => 'Pink — zawodnik',
        SlaviaPreset.dark => 'Dark — zawodnik',
        SlaviaPreset.slavia => 'Slavia — sala klubu',
        SlaviaPreset.iron => 'Żeliwo i stal',
        SlaviaPreset.arena => 'Światła areny',
        SlaviaPreset.platform => 'Platforma startowa',
        SlaviaPreset.midnight => 'Midnight lift',
        SlaviaPreset.ruby => 'Ruby podium',
        SlaviaPreset.neon => 'Neon gym',
        SlaviaPreset.blackgym => 'Black gym',
      };

  static String subtitle(SlaviaPreset p) => switch (p) {
        SlaviaPreset.pink =>
          'Akcent różowy dla kont zawodniczek (domyślnie wg płci).',
        SlaviaPreset.dark =>
          'Mocny ciemny preset dla kont zawodników (domyślnie wg płci).',
        SlaviaPreset.slavia =>
          'Świeży jasny motyw i klasyczny ciemny z klubową zielenią.',
        SlaviaPreset.iron =>
          'Chłodne odcienie jak rack i talerze na siłowni.',
        SlaviaPreset.arena =>
          'Ciepłe reflektory i kontrast jak przy podejściu na podium.',
        SlaviaPreset.platform =>
          'Minimalizm i mocny akcent — skupienie przed podejściem.',
        SlaviaPreset.midnight =>
          'Głęboki kontrast i akcent jak światło na nocnej sali.',
        SlaviaPreset.ruby =>
          'Ciepłe tło i rubinowy akcent — „ostatnie podejście”.',
        SlaviaPreset.neon =>
          'Jaskrawe neony i energia siłowni — widoczna zmiana.',
        SlaviaPreset.blackgym =>
          'Czarna sala jako kolor przewodni — kontrast i spokój.',
      };

  /// Kolejność jak w panelu „Profil” na WWW.
  static const List<SlaviaPreset> displayOrder = [
    SlaviaPreset.pink,
    SlaviaPreset.dark,
    SlaviaPreset.slavia,
    SlaviaPreset.iron,
    SlaviaPreset.arena,
    SlaviaPreset.platform,
    SlaviaPreset.midnight,
    SlaviaPreset.ruby,
    SlaviaPreset.neon,
    SlaviaPreset.blackgym,
  ];
}

class ThemeProvider with ChangeNotifier {
  ThemeProvider(this._prefs) {
    _preset =
        ThemeProvider.parsePreset(_prefs.getString(_kPreset)) ??
            SlaviaPreset.slavia;
    _themeMode = ThemeProvider._parseMode(_prefs.getString(_kMode));
  }

  static const _kPreset = 'slavia_mobile_ui_theme_preset';
  static const _kMode = 'slavia_mobile_ui_color_mode';

  final SharedPreferences _prefs;
  ApiService? _api;

  SlaviaPreset _preset = SlaviaPreset.slavia;
  ThemeMode _themeMode = ThemeMode.dark;

  SlaviaPreset get preset => _preset;
  ThemeMode get themeMode => _themeMode;

  /// Wywołaj po utworzeniu [ApiService], żeby przy zmianie motywu zapisywać na koncie (jak WWW).
  void attachApi(ApiService api) => _api = api;

  /// Po `/api/auth/me` — preferencje z konta nadpisują lokalne (gdy są ustawione).
  Future<void> syncFromAuthUser(AuthUser? user) async {
    if (user == null) return;
    var changed = false;

    final remotePreset = user.uiThemePreset?.trim();
    if (remotePreset != null && remotePreset.isNotEmpty) {
      final p = ThemeProvider.parsePreset(remotePreset);
      if (p != null && p != _preset) {
        _preset = p;
        changed = true;
      }
    }

    final remoteMode = user.uiColorMode?.trim().toLowerCase();
    if (remoteMode == 'light' ||
        remoteMode == 'dark' ||
        remoteMode == 'system') {
      final m = ThemeProvider._parseMode(remoteMode);
      if (m != _themeMode) {
        _themeMode = m;
        changed = true;
      }
    }

    if (changed) {
      await _persistLocal();
      notifyListeners();
    }
  }

  Future<void> setPreset(SlaviaPreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    await _persistLocal();
    notifyListeners();
    await _pushRemoteBestEffort();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _persistLocal();
    notifyListeners();
    await _pushRemoteBestEffort();
  }

  Future<void> _persistLocal() async {
    await _prefs.setString(_kPreset, presetToStorage(_preset));
    await _prefs.setString(_kMode, modeToStorage(_themeMode));
  }

  Future<void> _pushRemoteBestEffort() async {
    final api = _api;
    if (api == null) return;
    final token = await api.getToken();
    if (token == null) return;
    try {
      await api.updateProfile(
        uiThemePreset: presetToStorage(_preset),
        uiColorMode: apiColorMode(_themeMode),
      );
    } catch (_) {}
  }

  ThemeData getTheme(bool isDark) {
    final colors = _getPresetColors(_preset, isDark);
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    final baseScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      onSurface: colors.onSurface,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    final outline = colors.onSurface.withValues(alpha: isDark ? 0.14 : 0.08);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: baseScheme.copyWith(
        tertiary: const Color(0xFFF59E0B),
        onTertiary: const Color(0xFF1C1917),
        outline: outline,
        outlineVariant: outline,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
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
          side: BorderSide(color: outline),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: outline.withValues(alpha: 0.65)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displaySmall: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: colors.onSurface.withValues(alpha: 0.92),
        ),
      ),
    );
  }

  /// Kropka podglądu na liście presetów (ten sam akcent co w ciemnym wariancie).
  Color previewAccent(SlaviaPreset p) => _getPresetColors(p, true).primary;

  _PresetColors _getPresetColors(SlaviaPreset preset, bool isDark) {
    switch (preset) {
      case SlaviaPreset.pink:
        return _PresetColors(
          primary: const Color(0xFFEC4899),
          secondary: const Color(0xFFDB2777),
          background: isDark ? const Color(0xFF140910) : const Color(0xFFFFF5FA),
          surface: isDark ? const Color(0xFF1F1018) : Colors.white,
          card: isDark ? const Color(0xFF23121C) : Colors.white,
          onSurface: isDark ? const Color(0xFFFCE7F3) : const Color(0xFF4A041D),
        );
      case SlaviaPreset.dark:
        return isDark
            ? _PresetColors(
                primary: const Color(0xFF22C55E),
                secondary: const Color(0xFF16A34A),
                background: const Color(0xFF030712),
                surface: const Color(0xFF0B1220),
                card: const Color(0xFF111827),
                onSurface: const Color(0xFFF9FAFB),
              )
            : _PresetColors(
                primary: const Color(0xFF15803D),
                secondary: const Color(0xFF16A34A),
                background: const Color(0xFFF8FAFC),
                surface: Colors.white,
                card: Colors.white,
                onSurface: const Color(0xFF0F172A),
              );
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
          background: isDark
              ? const Color(0xFF0B1220)
              : const Color(0xFFF6F8FC),
          surface: isDark ? const Color(0xFF0F172A) : Colors.white,
          card: isDark ? const Color(0xFF0F172A) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF0C1528),
        );
      case SlaviaPreset.arena:
        return _PresetColors(
          primary: const Color(0xFFFBBF24),
          secondary: const Color(0xFFD97706),
          background: isDark
              ? const Color(0xFF120F0D)
              : const Color(0xFFFFFAF5),
          surface: isDark ? const Color(0xFF1C1410) : Colors.white,
          card: isDark ? const Color(0xFF1C1410) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF1F1612),
        );
      case SlaviaPreset.platform:
        return _PresetColors(
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF059669),
          background: isDark
              ? const Color(0xFF07120E)
              : const Color(0xFFF5FBF8),
          surface: isDark ? const Color(0xFF0F1A16) : Colors.white,
          card: isDark ? const Color(0xFF13251F) : Colors.white,
          onSurface: isDark ? const Color(0xFFECFDF5) : const Color(0xFF05201A),
        );
      case SlaviaPreset.midnight:
        return _PresetColors(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF4F46E5),
          background: isDark ? const Color(0xFF0C0E1A) : const Color(0xFFF5F7FF),
          surface: isDark ? const Color(0xFF15192E) : Colors.white,
          card: isDark ? const Color(0xFF1B2140) : Colors.white,
          onSurface: isDark ? const Color(0xFFEEF2FF) : const Color(0xFF111827),
        );
      case SlaviaPreset.ruby:
        return _PresetColors(
          primary: const Color(0xFFEF4444),
          secondary: const Color(0xFFB91C1C),
          background: isDark
              ? const Color(0xFF1A0B0B)
              : const Color(0xFFFFF9F8),
          surface: isDark ? const Color(0xFF281212) : Colors.white,
          card: isDark ? const Color(0xFF281212) : Colors.white,
          onSurface: isDark ? Colors.white : const Color(0xFF1C1010),
        );
      case SlaviaPreset.neon:
        return _PresetColors(
          primary: const Color(0xFFD946EF),
          secondary: const Color(0xFFC026D3),
          background: isDark ? const Color(0xFF140714) : const Color(0xFFFFF5FD),
          surface: isDark ? const Color(0xFF1F0C22) : Colors.white,
          card: isDark ? const Color(0xFF2A1030) : Colors.white,
          onSurface: isDark ? const Color(0xFFFAE8FF) : const Color(0xFF4A044E),
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
    }
  }

  static SlaviaPreset? parsePreset(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'pink':
        return SlaviaPreset.pink;
      case 'dark':
        return SlaviaPreset.dark;
      case 'slavia':
        return SlaviaPreset.slavia;
      case 'iron':
        return SlaviaPreset.iron;
      case 'arena':
        return SlaviaPreset.arena;
      case 'platform':
        return SlaviaPreset.platform;
      case 'midnight':
        return SlaviaPreset.midnight;
      case 'ruby':
        return SlaviaPreset.ruby;
      case 'neon':
        return SlaviaPreset.neon;
      case 'blackgym':
        return SlaviaPreset.blackgym;
      default:
        return null;
    }
  }

  static String presetToStorage(SlaviaPreset p) => switch (p) {
        SlaviaPreset.pink => 'pink',
        SlaviaPreset.dark => 'dark',
        SlaviaPreset.slavia => 'slavia',
        SlaviaPreset.iron => 'iron',
        SlaviaPreset.arena => 'arena',
        SlaviaPreset.platform => 'platform',
        SlaviaPreset.midnight => 'midnight',
        SlaviaPreset.ruby => 'ruby',
        SlaviaPreset.neon => 'neon',
        SlaviaPreset.blackgym => 'blackgym',
      };

  static ThemeMode _parseMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String modeToStorage(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  /// Wartości jak w API (`light` / `dark` / `system`).
  static String apiColorMode(ThemeMode m) => modeToStorage(m);
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
