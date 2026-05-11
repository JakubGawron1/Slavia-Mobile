/// Bazowy URL API (bez końcowego `/`).
/// Nadpisz przy buildzie / run: `--dart-define=SLAVIA_API_BASE=https://twoj-backend.example.com`
abstract final class ApiBase {
  ApiBase._();

  static const String url = String.fromEnvironment(
    'SLAVIA_API_BASE',
    defaultValue: 'https://slavia-backend.onrender.com',
  );

  static String get normalized {
    final t = url.trim();
    if (t.isEmpty) return 'https://slavia-backend.onrender.com';
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
