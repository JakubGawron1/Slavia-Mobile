import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'api_service_public_ext.dart';

const panelNavFlagPrefix = 'panel_nav_';

/// Cache flag nawigacji panelu (parity z `usePanelNavigationFlags` na WWW).
class PanelNavigationService extends ChangeNotifier {
  PanelNavigationService(this._api);

  final ApiService _api;
  Map<String, bool> _global = {};
  DateTime? _loadedAt;

  Map<String, bool> get globalFlags => Map.unmodifiable(_global);

  bool isModuleEnabled(String flagId, {bool defaultEnabled = true}) {
    if (!flagId.startsWith(panelNavFlagPrefix)) {
      return defaultEnabled;
    }
    return _global[flagId] ?? defaultEnabled;
  }

  Future<void> refresh({bool force = false}) async {
    if (!force &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 10)) {
      return;
    }
    try {
      final rows = await _api.getFeatureFlags();
      final next = <String, bool>{};
      for (final row in rows) {
        final name = (row['name'] as String?)?.trim() ?? '';
        if (!name.startsWith(panelNavFlagPrefix)) continue;
        if ((row['user_id'] as String?)?.trim().isNotEmpty == true) continue;
        next[name] = row['value'] == true;
      }
      _global = next;
      _loadedAt = DateTime.now();
      notifyListeners();
    } catch (_) {
      // offline — zostaw poprzedni cache lub domyślne włączone
    }
  }
}
