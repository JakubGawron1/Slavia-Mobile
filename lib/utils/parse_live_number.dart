/// Jak `parseLiveNumber` z Slavia-frontend (`app/utils/liveNumber.ts`) —
/// pozwala pisać „120.” / „120,” bez traktowania jako gotowej wartości do relacji.
double? parseLiveNumber(String? raw) {
  final v = raw ?? '';
  final trimmed = v.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.endsWith('.') || trimmed.endsWith(',')) return null;
  final normalized = trimmed.replaceAll(',', '.');
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}
