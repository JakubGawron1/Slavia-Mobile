import 'dart:convert';

/// Prosty cache w pamięci dla publicznych GET-ów (TTL). Zmniejsza ruch przy powrocie do ekranu.
class PublicApiCache {
  PublicApiCache._();
  static final PublicApiCache instance = PublicApiCache._();

  final Map<String, _CacheEntry> _store = {};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 3)}) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void invalidate(String key) => _store.remove(key);

  void clear() => _store.clear();

  /// Klucz stabilny dla listy JSON (sortowane pola w URI).
  static String keyFor(String path, {Map<String, String>? query}) {
    if (query == null || query.isEmpty) return path;
    final q = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return '$path?${q.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static String decodeJsonBody(String body) => body;

  static dynamic decodeJson(String body) => jsonDecode(body);
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);
  final Object? value;
  final DateTime expiresAt;
}
