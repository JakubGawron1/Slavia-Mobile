import 'dart:convert';
import 'package:flutter/services.dart';

/// Metadane presetów z `slavia_shared` JSON (Fala 3 — theme z shared).
class ThemePresetCatalog {
  ThemePresetCatalog._();

  static Map<String, _PresetMeta>? _cache;

  static Future<void> ensureLoaded() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString(
      'packages/slavia_shared/assets/theme-presets.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final presets = json['presets'] as List<dynamic>? ?? [];
    final map = <String, _PresetMeta>{};
    for (final item in presets) {
      final m = item as Map<String, dynamic>;
      final id = (m['id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      map[id] = _PresetMeta(
        label: (m['label'] as String?) ?? id,
        description: (m['description'] as String?) ?? '',
        experimental: m['experimental'] == true,
      );
    }
    _cache = map;
  }

  static String? labelForStorageId(String storageId) {
    return _cache?[storageId]?.label;
  }

  static String? descriptionForStorageId(String storageId) {
    return _cache?[storageId]?.description;
  }

  static bool isExperimentalStorageId(String storageId) {
    return _cache?[storageId]?.experimental ?? false;
  }
}

class _PresetMeta {
  const _PresetMeta({
    required this.label,
    required this.description,
    required this.experimental,
  });

  final String label;
  final String description;
  final bool experimental;
}
