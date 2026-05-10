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
      id: json['id'],
      kind: json['kind'],
      title: json['title'],
      body: json['body'],
      payload: json['payload'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}
