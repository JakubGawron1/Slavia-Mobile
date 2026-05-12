import 'dart:io';

/// Krótkie, zrozumiałe komunikaty po polsku — na Snackbar / empty error states.
String friendlyNetworkError(Object error) {
  final raw = error.toString();
  final s = raw.toLowerCase();

  if (error is SocketException ||
      s.contains('failed host lookup') ||
      s.contains('no address associated with hostname')) {
    return 'Brak połączenia lub nie udało się znaleźć serwera (DNS). '
        'Sprawdź internet lub ustawienia sieci.';
  }
  if (s.contains('certificate_verify_failed') ||
      s.contains('handshake exception')) {
    return 'Problem z certyfikatem TLS — sprawdź datę urządzenia i sieć.';
  }
  if (s.contains('timed out') ||
      s.contains('timeout') ||
      s.contains('connection reset')) {
    return 'Serwer nie odpowiedział na czas. Spróbuj ponownie za chwilę.';
  }
  if (s.contains('401') || s.contains('unauthorized')) {
    return 'Sesja wygasła lub brak uprawnień — wyloguj się i zaloguj ponownie.';
  }
  if (s.contains('403') || s.contains('forbidden')) {
    return 'Brak uprawnień do tej operacji.';
  }
  if (s.contains('404')) {
    return 'Nie znaleziono zasobu na serwerze.';
  }
  if (s.contains('500') ||
      s.contains('502') ||
      s.contains('503') ||
      s.contains('internal server')) {
    return 'Serwer ma chwilowy problem. Spróbuj później.';
  }

  if (raw.length > 160) {
    return '${raw.substring(0, 157)}…';
  }
  return raw;
}
