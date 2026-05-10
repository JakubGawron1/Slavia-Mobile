class Announcement {
  final String id;
  final String title;
  final String body;
  final bool pinned;
  final int sortOrder;
  final bool published;
  final String authorId;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.pinned,
    required this.sortOrder,
    required this.published,
    required this.authorId,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      pinned: json['pinned'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      published: json['published'] ?? true,
      authorId: json['author_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
