import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_base.dart';

/// Metadane presetów z `GET /api/system/theme-presets`.
class ThemePresetCatalog {
  ThemePresetCatalog._();

  static Map<String, _PresetMeta>? _cache;

  static const Map<String, _PresetMeta> _fallback = {
    'pink': _PresetMeta(
      label: 'Pink — athlete',
      description: 'Akcent różowy dla kont zawodniczek (domyślny wg płci).',
      experimental: false,
    ),
    'dark': _PresetMeta(
      label: 'Dark — athlete',
      description: 'Mocny ciemny preset dla kont zawodników (domyślny wg płci).',
      experimental: false,
    ),
    'slavia': _PresetMeta(
      label: 'Slavia — sala klubu',
      description: 'Ciepłe bordo i łososiowy akcent — charakter klubu.',
      experimental: false,
    ),
  };

  static Future<void> ensureLoaded() async {
    if (_cache != null) return;
    try {
      final uri = Uri.parse('${ApiBase.normalized}/api/system/theme-presets');
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
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
        if (map.isNotEmpty) {
          _cache = map;
          return;
        }
      }
    } catch (_) {
      /* fallback */
    }
    _cache = Map<String, _PresetMeta>.from(_fallback);
  }

  static String? labelForStorageId(String storageId) {
    return _cache?[storageId]?.label ?? _fallback[storageId]?.label;
  }

  static String? descriptionForStorageId(String storageId) {
    return _cache?[storageId]?.description ?? _fallback[storageId]?.description;
  }

  static bool isExperimentalStorageId(String storageId) {
    return _cache?[storageId]?.experimental ?? _fallback[storageId]?.experimental ?? false;
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
