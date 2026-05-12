class AuthResponse {
  final String token;
  final List<String> roles;
  final String userId;

  AuthResponse({
    required this.token,
    required this.roles,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      roles: List<String>.from(json['roles']),
      userId: json['user_id'],
    );
  }
}

class AuthUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final List<String> roles;
  final bool isBanned;
  final String? bannedReason;
  final bool? totpEnabled;
  final String? athleteId;
  final String? athleteImageUrl;
  final String? email;
  /// Jak `/profil` na WWW — motyw zapisany na koncie.
  final String? uiThemePreset;
  final String? uiColorMode;
  final String? athleteGender;

  AuthUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.roles,
    required this.isBanned,
    this.bannedReason,
    this.totpEnabled,
    this.athleteId,
    this.athleteImageUrl,
    this.email,
    this.uiThemePreset,
    this.uiColorMode,
    this.athleteGender,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      roles: List<String>.from(json['roles']),
      isBanned: json['is_banned'] ?? false,
      bannedReason: json['banned_reason'],
      totpEnabled: json['totp_enabled'],
      athleteId: json['athlete_id'],
      athleteImageUrl: json['athlete_image_url'],
      email: json['email'],
      uiThemePreset: json['ui_theme_preset'] as String?,
      uiColorMode: json['ui_color_mode'] as String?,
      athleteGender: json['athlete_gender'] as String?,
    );
  }
}

class CompetitionResult {
  final String id;
  final String athleteId;
  final String date;
  final String kind; // competition, training
  final String? location;
  final double? snatch;
  final double? cleanAndJerk;
  final double total;
  final String status; // Pending, Approved, Rejected

  CompetitionResult({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.kind,
    this.location,
    this.snatch,
    this.cleanAndJerk,
    required this.total,
    required this.status,
  });

  factory CompetitionResult.fromJson(Map<String, dynamic> json) {
    return CompetitionResult(
      id: json['id'],
      athleteId: json['athlete_id'],
      date: json['date'],
      kind: json['kind'],
      location: json['location'],
      snatch: (json['snatch'] as num?)?.toDouble(),
      cleanAndJerk: (json['clean_and_jerk'] as num?)?.toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] ?? 'Pending',
    );
  }
}
