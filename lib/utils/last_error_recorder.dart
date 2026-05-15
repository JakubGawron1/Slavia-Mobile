import 'network_feedback.dart';

/// Ostatni komunikat błędu (np. sieć) — używany przy zgłoszeniach z profilu (idea #139).
abstract final class LastErrorRecorder {
  LastErrorRecorder._();

  static String? _friendly;
  static DateTime? _at;

  static String? get friendlyPreview => _friendly;

  static DateTime? get recordedAt => _at;

  static void record(Object error) {
    _friendly = friendlyNetworkError(error);
    _at = DateTime.now();
  }

  static void clear() {
    _friendly = null;
    _at = null;
  }
}
