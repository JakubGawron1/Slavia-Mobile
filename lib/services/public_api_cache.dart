import 'dart:async';
import 'dart:convert';

import 'persistent_api_cache.dart';

/// Prosty cache w pamięci + dysk dla publicznych GET-ów (TTL). Zmniejsza ruch przy powrocie do ekranu.
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

  Future<T?> getDisk<T>(String key) async {
    final raw = await PersistentApiCache.instance.getJson(key);
    if (raw is T) return raw;
    if (raw is String && T == String) return raw as T;
    return null;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 3)}) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
    if (value is String) {
      unawaited(
        PersistentApiCache.instance.setJson(key, value, maxAge: const Duration(days: 7)),
      );
    }
  }

  void invalidate(String path) {
    _store.remove(path);
    unawaited(PersistentApiCache.instance.remove(path));
  }

  void clear() {
    _store.clear();
    unawaited(PersistentApiCache.instance.clearAll());
  }

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
