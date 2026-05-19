import 'dart:convert';

/// Błąd logowania z parsowaniem odpowiedzi JSON API (`message`, opcjonalnie `code`).
class LoginApiException implements Exception {
  LoginApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isTotpRequired => message == 'totp_required';

  static LoginApiException fromResponse(int statusCode, String body) {
    try {
      final decoded = body.trim();
      if (decoded.startsWith('{')) {
        final map = jsonDecode(decoded);
        if (map is Map<String, dynamic>) {
          final msg = map['message']?.toString().trim();
          if (msg != null && msg.isNotEmpty) {
            return LoginApiException(msg, statusCode: statusCode);
          }
        }
      }
    } catch (_) {}
    if (body.trim().isNotEmpty) {
      return LoginApiException(body.trim(), statusCode: statusCode);
    }
    return LoginApiException('Logowanie nie powiodło się.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
