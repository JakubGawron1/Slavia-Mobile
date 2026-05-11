/// Wspólna logika masy do Sinclaira (jak `~/utils/sinclairAthlete.ts` na frontendzie).
double parseWeightCategoryLimitKg(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return 0;
  final parts = t.split(RegExp(r'[—–-]'));
  final segment = (parts.isNotEmpty ? parts.last : t).trim();
  final m = RegExp(
    r'(\+?\d+(?:\.\d+)?)\s*kg',
    caseSensitive: false,
  ).firstMatch(segment);
  if (m == null) return 0;
  return double.tryParse(m.group(1)!.replaceAll('+', '')) ?? 0;
}

double effectiveBodyweightKgForSinclair({
  double? bodyweight,
  String? weightCategory,
}) {
  if (bodyweight != null && bodyweight.isFinite && bodyweight > 0)
    return bodyweight;
  final fromCat = parseWeightCategoryLimitKg(weightCategory);
  return fromCat > 0 ? fromCat : 0;
}
