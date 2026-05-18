import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Trwały cache JSON (stale-while-revalidate przy starcie aplikacji).
class PersistentApiCache {
  PersistentApiCache._();
  static final PersistentApiCache instance = PersistentApiCache._();

  static const _prefix = 'slavia_disk_cache_v1_';

  Future<void> setJson(String key, Object data, {Duration? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = <String, dynamic>{
      'saved_at': DateTime.now().toIso8601String(),
      if (maxAge != null) 'expires_at': DateTime.now().add(maxAge).toIso8601String(),
      'data': data,
    };
    await prefs.setString('$_prefix$key', jsonEncode(envelope));
  }

  Future<Object?> getJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final expires = envelope['expires_at'] as String?;
      if (expires != null) {
        final exp = DateTime.tryParse(expires);
        if (exp != null && DateTime.now().isAfter(exp)) {
          await prefs.remove('$_prefix$key');
          return null;
        }
      }
      return envelope['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
