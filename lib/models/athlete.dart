class Athlete {
  final String id;
  final String? userId;
  final String fullName;
  final int? birthYear;
  final String? gender;
  final String? weightCategory;
  final double? bodyweight;
  final double? bestSnatchKg;
  final double? bestCleanJerkKg;
  final double? totalKg;
  final String? imageUrl;
  final String? notes;
  final String? tagline;
  final String? bio;
  final bool isActive;
  final bool hasStandingOrder;

  Athlete({
    required this.id,
    this.userId,
    required this.fullName,
    this.birthYear,
    this.gender,
    this.weightCategory,
    this.bodyweight,
    this.bestSnatchKg,
    this.bestCleanJerkKg,
    this.totalKg,
    this.imageUrl,
    this.notes,
    this.tagline,
    this.bio,
    required this.isActive,
    required this.hasStandingOrder,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      birthYear: json['birth_year'],
      gender: json['gender'],
      weightCategory: json['weight_category'],
      bodyweight: (json['bodyweight'] as num?)?.toDouble(),
      bestSnatchKg: (json['best_snatch_kg'] as num?)?.toDouble(),
      bestCleanJerkKg: (json['best_clean_jerk_kg'] as num?)?.toDouble(),
      totalKg: (json['total_kg'] as num?)?.toDouble(),
      imageUrl: json['image_url'],
      notes: json['notes'],
      tagline: json['profile_tagline'],
      bio: json['public_bio'],
      isActive: json['is_active'] ?? true,
      hasStandingOrder: json['has_standing_order'] ?? false,
    );
  }
}

class TrainingLogEntry {
  final String id;
  final String athleteId;
  final String sessionDate;
  final String? title;
  final String notes;
  final String createdAt;
  final String? authorUserId;
  final String? authorUsername;

  TrainingLogEntry({
    required this.id,
    required this.athleteId,
    required this.sessionDate,
    this.title,
    required this.notes,
    required this.createdAt,
    this.authorUserId,
    this.authorUsername,
  });

  factory TrainingLogEntry.fromJson(Map<String, dynamic> json) {
    return TrainingLogEntry(
      id: json['id'],
      athleteId: json['athlete_id'],
      sessionDate: json['session_date'],
      title: json['title'],
      notes: json['notes'],
      createdAt: json['created_at'],
      authorUserId: json['author_user_id'],
      authorUsername: json['author_username'],
    );
  }
}
