/// Punkt osi czasu zawodnika — `/api/athletes/{id}/timeline`.
class AthleteTimelineItem {
  final String id;
  final String kind;
  final DateTime at;
  final String title;
  final String detail;

  AthleteTimelineItem({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.detail,
  });

  factory AthleteTimelineItem.fromJson(Map<String, dynamic> json) {
    return AthleteTimelineItem(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? '',
      at: DateTime.parse(json['at'] as String),
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}
