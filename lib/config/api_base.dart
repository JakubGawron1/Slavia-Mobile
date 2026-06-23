import '../config/brand_defaults.dart';

/// Bazowy URL API (bez końcowego `/`).
/// Nadpisz przy buildzie / run: `--dart-define=SLAVIA_API_BASE=https://twoj-backend.example.com`
abstract final class ApiBase {
  ApiBase._();

  static const String url = String.fromEnvironment(
    'SLAVIA_API_BASE',
    defaultValue: SlaviaBrandDefaults.apiBase,
  );

  static String get normalized {
    final t = url.trim();
    if (t.isEmpty) return SlaviaBrandDefaults.apiBase;
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
