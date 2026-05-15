class GalleryPhoto {
  final String id;
  final String imageUrl;
  final String mediaType;
  final String? caption;
  final int sortOrder;
  final bool published;
  final String authorId;
  final DateTime createdAt;

  GalleryPhoto({
    required this.id,
    required this.imageUrl,
    required this.mediaType,
    required this.caption,
    required this.sortOrder,
    required this.published,
    required this.authorId,
    required this.createdAt,
  });

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      mediaType: json['media_type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      published: json['published'] as bool? ?? true,
      authorId: json['author_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isVideo =>
      mediaType.toLowerCase() == 'video' ||
      imageUrl.toLowerCase().contains('.mp4');
}
