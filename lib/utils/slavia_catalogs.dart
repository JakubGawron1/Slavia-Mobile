import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_base.dart';
import 'athlete_badge_catalog.dart';

/// Ładuje katalog odznak z backendu (opcjonalnie przy starcie).
Future<void> hydrateAthleteBadgeCatalogFromApi() async {
  try {
    final uri = Uri.parse('${ApiBase.normalized}/api/system/athlete-badges');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['badges'] as List<dynamic>? ?? [];
    final parsed = <AthleteBadgeMeta>[];
    for (final item in items) {
      final m = item as Map<String, dynamic>;
      final id = (m['id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      final thresholds = (m['thresholds'] as List<dynamic>? ?? [])
          .map((t) => (t as num).toDouble())
          .toList();
      parsed.add(
        AthleteBadgeMeta(
          id: id,
          label: (m['label'] as String?) ?? id,
          description: (m['description'] as String?) ?? '',
          thresholds: thresholds,
          unit: (m['unit'] as String?) ?? '',
        ),
      );
    }
    AthleteBadgeCatalog.replaceBadges(parsed);
  } catch (_) {
    /* zostaje fallback */
  }
}
