import 'package:quick_actions/quick_actions.dart';

import '../utils/app_shortcuts_bridge.dart';

const _kChat = 'shortcut_chat';
const _kTraining = 'shortcut_training';
const _kCalendar = 'shortcut_calendar';

/// Skróty na ekranie głównym (Android / iOS) — idea #112 (oraz #111 — podtytuł „Moje starty”).
class AppShortcutsService {
  AppShortcutsService._();
  static final AppShortcutsService instance = AppShortcutsService._();

  final QuickActions _qa = QuickActions();
  bool _ready = false;

  List<ShortcutItem> _buildItems({required String calendarSubtitle}) {
    return <ShortcutItem>[
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
      ShortcutItem(
        type: _kCalendar,
        localizedTitle: 'Moje starty',
        localizedSubtitle: calendarSubtitle,
      ),
    ];
  }

  Future<void> ensureInitialized() async {
    if (_ready) return;
    _ready = true;
    await _qa.initialize((type) {
      AppShortcutsBridge.pendingType = type;
    });
    await _qa.setShortcutItems(
      _buildItems(calendarSubtitle: 'Kalendarz zawodów'),
    );
  }

  /// Ustawia drugi wiersz skrótu „Moje starty” (treść z najbliższego wpisu — idea #111).
  Future<void> updateCalendarShortcutSubtitle(String? subtitle) async {
    if (!_ready) {
      await ensureInitialized();
    }
    final sub =
        subtitle == null || subtitle.trim().isEmpty
            ? 'Kalendarz zawodów'
            : subtitle.trim();
    await _qa.setShortcutItems(_buildItems(calendarSubtitle: sub));
  }
}
