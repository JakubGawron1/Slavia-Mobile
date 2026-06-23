class BadgeThresholds {
  final List<double> thresholds;
  final double current;

  const BadgeThresholds({required this.thresholds, required this.current});
}

int getBadgeLevel(BadgeThresholds badge) {
  var level = 0;
  for (final t in badge.thresholds) {
    if (badge.current >= t) level++;
  }
  return level;
}

double getBadgeProgressPercent(BadgeThresholds badge) {
  final level = getBadgeLevel(badge);
  if (level >= badge.thresholds.length) return 100;
  final prev = level == 0 ? 0.0 : badge.thresholds[level - 1];
  final next = badge.thresholds[level];
  if (next <= prev) return 100;
  return ((badge.current - prev) / (next - prev) * 100).clamp(0, 100);
}

double? getNextBadgeThreshold(BadgeThresholds badge) {
  final level = getBadgeLevel(badge);
  return level < badge.thresholds.length ? badge.thresholds[level] : null;
}
