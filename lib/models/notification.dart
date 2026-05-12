class ClubNotification {
  final String id;
  final String kind;
  final String title;
  final String body;
  final String? payload;
  final DateTime createdAt;
  final bool isRead;

  ClubNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    required this.isRead,
  });

  factory ClubNotification.fromJson(Map<String, dynamic> json) {
    return ClubNotification(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      payload: json['payload']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}
