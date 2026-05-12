/// Przekazanie typu skrótu (quick_actions) do [MainScreen] po starcie / wznowieniu.
class AppShortcutsBridge {
  AppShortcutsBridge._();

  static String? pendingType;

  static String? takePending() {
    final t = pendingType;
    pendingType = null;
    return t;
  }
}
