import 'package:quick_actions/quick_actions.dart';

import '../utils/app_shortcuts_bridge.dart';

const _kChat = 'shortcut_chat';
const _kTraining = 'shortcut_training';

/// Skróty na ekranie głównym (Android / iOS) — idea #112.
class AppShortcutsService {
  AppShortcutsService._();
  static final AppShortcutsService instance = AppShortcutsService._();

  final QuickActions _qa = QuickActions();
  bool _ready = false;

  Future<void> ensureInitialized() async {
    if (_ready) return;
    _ready = true;
    await _qa.initialize((type) {
      AppShortcutsBridge.pendingType = type;
    });
    await _qa.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: _kChat,
        localizedTitle: 'Czat z trenerem',
        localizedSubtitle: 'CKS Slavia',
      ),
      const ShortcutItem(
        type: _kTraining,
        localizedTitle: 'Dziennik treningów',
        localizedSubtitle: 'CKS Slavia',
      ),
    ]);
  }
}
