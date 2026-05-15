class ClubPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? imageUrl;
  final DateTime createdAt;
  final bool published;

  ClubPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.imageUrl,
    required this.createdAt,
    required this.published,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      published: json['published'] as bool? ?? true,
    );
  }
}
