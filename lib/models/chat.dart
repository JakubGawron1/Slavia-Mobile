class ChatThread {
  final String id;
  final String athleteUserId;
  final String trainerUserId;
  final String? title;
  final String createdAt;
  final String updatedAt;
  final String? peerLastSeenAt;
  final bool peerOnline;

  ChatThread({
    required this.id,
    required this.athleteUserId,
    required this.trainerUserId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.peerLastSeenAt,
    this.peerOnline = false,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      athleteUserId: json['athlete_user_id'] as String,
      trainerUserId: json['trainer_user_id'] as String,
      title: json['title'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      peerLastSeenAt: json['peer_last_seen_at'] as String?,
      peerOnline: json['peer_online'] == true,
    );
  }
}

class ChatReactionSummary {
  final String emoji;
  final int count;
  final bool reactedByMe;

  ChatReactionSummary({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  factory ChatReactionSummary.fromJson(Map<String, dynamic> json) {
    return ChatReactionSummary(
      emoji: json['emoji'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      reactedByMe: json['reacted_by_me'] == true,
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
  final List<ChatReactionSummary> reactions;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
    this.senderUsername,
    this.senderPhotoUrl,
    this.reactions = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
    final reactions = rawReactions is List
        ? rawReactions
            .map(
              (e) => ChatReactionSummary.fromJson(e as Map<String, dynamic>),
            )
            .toList()
        : <ChatReactionSummary>[];
    return ChatMessage(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      senderUserId: json['sender_user_id'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String,
      senderUsername: json['sender_username'] as String?,
      senderPhotoUrl: json['sender_photo_url'] as String?,
      reactions: reactions,
    );
  }
}
