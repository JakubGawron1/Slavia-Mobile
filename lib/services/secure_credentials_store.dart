import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token i dane logowania w secure storage (idea #185).
class SecureCredentialsStore {
  SecureCredentialsStore._();
  static final SecureCredentialsStore instance = SecureCredentialsStore._();

  static const _tokenKey = 'auth_token_secure';
  static const _userKey = 'saved_username_secure';
  static const _passKey = 'saved_password_secure';
  static const _migratedKey = 'secure_store_migrated_v1';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _migrateFromPrefsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;
    final legacyToken = prefs.getString('auth_token');
    final legacyUser = prefs.getString('saved_username');
    final legacyPass = prefs.getString('saved_password');
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secure.write(key: _tokenKey, value: legacyToken);
      await prefs.remove('auth_token');
    }
    if (legacyUser != null) {
      await _secure.write(key: _userKey, value: legacyUser);
      await prefs.remove('saved_username');
    }
    if (legacyPass != null) {
      await _secure.write(key: _passKey, value: legacyPass);
      await prefs.remove('saved_password');
    }
    await prefs.setBool(_migratedKey, true);
  }

  Future<String?> readToken() async {
    await _migrateFromPrefsIfNeeded();
    return _secure.read(key: _tokenKey);
  }

  Future<void> writeToken(String? token) async {
    await _migrateFromPrefsIfNeeded();
    if (token == null || token.isEmpty) {
      await _secure.delete(key: _tokenKey);
    } else {
      await _secure.write(key: _tokenKey, value: token);
    }
  }

  Future<void> writeLoginCredentials(String username, String password) async {
    await _migrateFromPrefsIfNeeded();
    await _secure.write(key: _userKey, value: username);
    await _secure.write(key: _passKey, value: password);
  }

  Future<({String? username, String? password})> readLoginCredentials() async {
    await _migrateFromPrefsIfNeeded();
    final u = await _secure.read(key: _userKey);
    final p = await _secure.read(key: _passKey);
    return (username: u, password: p);
  }

  Future<void> clearLoginCredentials() async {
    await _secure.delete(key: _userKey);
    await _secure.delete(key: _passKey);
  }
}
