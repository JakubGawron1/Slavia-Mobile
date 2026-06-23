/// Metadane odznak — fallback offline; `hydrateFromApi` ładuje z backendu.
class AthleteBadgeMeta {
  final String id;
  final String label;
  final String description;
  final List<double> thresholds;
  final String unit;

  const AthleteBadgeMeta({
    required this.id,
    required this.label,
    required this.description,
    required this.thresholds,
    required this.unit,
  });
}

abstract final class AthleteBadgeCatalog {
  AthleteBadgeCatalog._();

  static List<AthleteBadgeMeta> _badges = List.unmodifiable(_defaultBadges);

  static List<AthleteBadgeMeta> get badges => _badges;

  static const List<AthleteBadgeMeta> _defaultBadges = [
    AthleteBadgeMeta(
      id: 'sinclair',
      label: 'Mistrz Sinclaira',
      description:
          'Punkty Sinclair wyliczane na podstawie masy ciała i wyniku w dwuboju.',
      thresholds: [100, 200, 300, 400],
      unit: 'pkt',
    ),
    AthleteBadgeMeta(
      id: 'total',
      label: 'Siła dwuboju',
      description: 'Suma najlepszego rwania i podrzutu.',
      thresholds: [100, 200, 300, 400],
      unit: 'kg',
    ),
    AthleteBadgeMeta(
      id: 'snatch',
      label: 'Technika rwania',
      description: 'Twój najlepszy wynik w rwaniu.',
      thresholds: [50, 90, 100, 120, 150],
      unit: 'kg',
    ),
    AthleteBadgeMeta(
      id: 'cj',
      label: 'Moc podrzutu',
      description: 'Twój najlepszy wynik w podrzucie.',
      thresholds: [70, 90, 100, 120, 150, 170, 200],
      unit: 'kg',
    ),
    AthleteBadgeMeta(
      id: 'trainings',
      label: 'Staż w klubie',
      description: 'Ilość obecności na treningach zarejestrowana w systemie.',
      thresholds: [10, 50, 100, 250, 500],
      unit: 'sesji',
    ),
  ];

  static void replaceBadges(List<AthleteBadgeMeta> next) {
    if (next.isEmpty) return;
    _badges = List.unmodifiable(next);
  }
}
