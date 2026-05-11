class ChatThread {
  final String id;
  final String athleteUserId;
  final String trainerUserId;
  final String? title;
  final String createdAt;
  final String updatedAt;

  ChatThread({
    required this.id,
    required this.athleteUserId,
    required this.trainerUserId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      athleteUserId: json['athlete_user_id'] as String,
      trainerUserId: json['trainer_user_id'] as String,
      title: json['title'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class ChatMessage {
  final String id;
  final String threadId;
  final String senderUserId;
  final String body;
  final String createdAt;
  final String? senderUsername;
  final String? senderPhotoUrl;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
    this.senderUsername,
    this.senderPhotoUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      senderUserId: json['sender_user_id'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String,
      senderUsername: json['sender_username'] as String?,
      senderPhotoUrl: json['sender_photo_url'] as String?,
    );
  }
}
