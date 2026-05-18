import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/auth.dart';
import '../models/athlete.dart';
import '../models/notification.dart';
import '../models/competition.dart';
import '../models/competition_participant.dart';
import '../models/announcement.dart';
import '../models/chat.dart';
import '../models/athlete_timeline_item.dart';
import '../models/training_plan.dart';
import '../models/exercise.dart';
import '../models/recovery_log.dart';
import '../models/attendance_summary.dart';
import '../models/club_post.dart';
import '../models/gallery_photo.dart';
import '../models/payment.dart';
import '../config/api_base.dart';
import 'dart:async';

import 'persistent_api_cache.dart';
import 'public_api_cache.dart';
import 'secure_credentials_store.dart';

class ApiService {
  static String get baseUrl => ApiBase.normalized;
  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await SecureCredentialsStore.instance.readToken();
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    await SecureCredentialsStore.instance.writeToken(token);
  }

  Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Publiczny GET z krótkim TTL w pamięci (zgodny z Cache-Control API).
  Future<http.Response> _getCachedPublic(
    String path, {
    Duration ttl = const Duration(minutes: 2),
    bool backgroundRefresh = false,
  }) async {
    final key = PublicApiCache.keyFor(path);
    final mem = PublicApiCache.instance.get<String>(key);
    if (mem != null) {
      if (backgroundRefresh) {
        unawaited(_refreshPublicGet(path, key, ttl));
      }
      return http.Response(mem, 200);
    }
    final disk = await PublicApiCache.instance.getDisk<String>(key);
    if (disk != null) {
      PublicApiCache.instance.set(key, disk, ttl: ttl);
      unawaited(_refreshPublicGet(path, key, ttl));
      return http.Response(disk, 200);
    }
    return _refreshPublicGet(path, key, ttl);
  }

  Future<http.Response> _refreshPublicGet(
    String path,
    String key,
    Duration ttl,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(null),
    );
    if (response.statusCode == 200) {
      PublicApiCache.instance.set(key, response.body, ttl: ttl);
    }
    return response;
  }

  static const _meCacheKey = 'auth_me';

  Future<AuthUser?> getCachedMe() async {
    final raw = await PersistentApiCache.instance.getJson(_meCacheKey);
    if (raw is Map<String, dynamic>) {
      return AuthUser.fromJson(raw);
    }
    return null;
  }

  Future<void> cacheMe(AuthUser user) async {
    await PersistentApiCache.instance.setJson(
      _meCacheKey,
      {
        'id': user.id,
        'username': user.username,
        'avatar_url': user.avatarUrl,
        'roles': user.roles,
        'is_banned': user.isBanned,
        'banned_reason': user.bannedReason,
        'totp_enabled': user.totpEnabled,
        'athlete_id': user.athleteId,
        'athlete_image_url': user.athleteImageUrl,
        'email': user.email,
        'ui_theme_preset': user.uiThemePreset,
        'ui_color_mode': user.uiColorMode,
        'athlete_gender': user.athleteGender,
        'athlete_birth_year': user.athleteBirthYear,
      },
      maxAge: const Duration(days: 30),
    );
  }

  // Auth
  Future<AuthResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final authData = AuthResponse.fromJson(jsonDecode(response.body));
      await setToken(authData.token);
      return authData;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<AuthUser> getMe() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final user = AuthUser.fromJson(jsonDecode(response.body));
      await cacheMe(user);
      return user;
    } else {
      throw Exception('Failed to get user data');
    }
  }

  Future<Map<String, dynamic>> qrCheckin({
    required String payload,
    required String sessionDate,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/qr-checkin'),
      headers: _headers(token),
      body: jsonEncode({
        'payload': payload,
        'session_date': sessionDate,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(response.body);
  }

  // Athletes
  Future<List<Athlete>> getAthletes() async {
    final response = await _getCachedPublic('/api/athletes');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Athlete.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load athletes');
    }
  }

  Future<Athlete> getAthlete(String id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/athletes/$id'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Athlete.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load athlete');
    }
  }

  Future<AttendanceSummary> getAttendanceSummary(String athleteId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/attendance/summary/$athleteId'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return AttendanceSummary.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'Failed to load attendance summary: ${response.statusCode}',
    );
  }

  // Notifications
  Future<List<ClubNotification>> getNotifications() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ClubNotification.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationRead(String id) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/api/notifications/${Uri.encodeComponent(id)}/read',
      ),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all read');
    }
  }

  Future<void> deleteNotification(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notifications/${Uri.encodeComponent(id)}'),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
  }

  Future<void> deleteAllNotifications() async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notifications'),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete all notifications');
    }
  }

  // Calendar / Competitions
  Future<List<Competition>> getCompetitions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/competitions'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Competition.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load competitions');
    }
  }

  /// Zawody przypisane do zalogowanego zawodnika (`competition_participants`), jak `/kalendarz` z filtrem „Moje starty”.
  Future<List<Competition>> getMyCalendarCompetitions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/athletes/my-calendar'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = (map['entries'] as List<dynamic>?) ?? [];
      return entries
          .map((e) => e as Map<String, dynamic>)
          .map(
            (e) =>
                Competition.fromJson(e['competition'] as Map<String, dynamic>),
          )
          .toList();
    }
    if (response.statusCode == 403) {
      throw Exception('calendar_athlete_only');
    }
    throw Exception('Failed to load my calendar');
  }

  /// ICS z backendu (`GET /api/system/calendar/export/{id}`) — idea #129.
  Future<List<int>> downloadCompetitionIcsBytes(String competitionId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/system/calendar/export/${Uri.encodeComponent(competitionId)}',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception(
      'ICS export failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// Skład startowy zawodów (`GET /api/competitions/{id}/participants`).
  Future<List<CompetitionParticipantBrief>> getCompetitionParticipants(
    String competitionId,
  ) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/competitions/${Uri.encodeComponent(competitionId)}/participants',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (e) => CompetitionParticipantBrief.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    throw Exception(
      'Failed to load participants: ${response.statusCode} ${response.body}',
    );
  }

  /// Nadpisuje listę przypisań (jak panel WWW — `PUT` z pełną listą `athlete_ids`).
  Future<void> setCompetitionParticipants(
    String competitionId,
    List<String> athleteIds,
  ) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/competitions/${Uri.encodeComponent(competitionId)}/participants',
      ),
      headers: _headers(token),
      body: jsonEncode({'athlete_ids': athleteIds}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to save roster: ${response.statusCode} ${response.body}',
      );
    }
  }

  // Announcements
  Future<List<Announcement>> getAnnouncements() async {
    final response = await _getCachedPublic('/api/announcements');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Announcement.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  /// Admin / SuperAdmin — pełna lista (nieopublikowane, kolejność).
  Future<List<Announcement>> getAnnouncementsManage() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/announcements/manage'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Announcement.fromJson(item)).toList();
    }
    throw Exception('announcements_manage_failed');
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String body,
    bool? pinned,
    int? sortOrder,
    bool? published,
  }) async {
    final token = await getToken();
    final payload = <String, dynamic>{
      'title': title.trim(),
      'body': body,
      if (pinned != null) 'pinned': pinned,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (published != null) 'published': published,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/announcements'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      PublicApiCache.instance.invalidate('/api/announcements');
      return Announcement.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('create_announcement_failed');
  }

  Future<Announcement> updateAnnouncement(
    String id, {
    required String title,
    required String body,
    bool? pinned,
    int? sortOrder,
    bool? published,
  }) async {
    final token = await getToken();
    final payload = <String, dynamic>{
      'title': title.trim(),
      'body': body,
      if (pinned != null) 'pinned': pinned,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (published != null) 'published': published,
    };
    final response = await http.patch(
      Uri.parse('$baseUrl/api/announcements/${Uri.encodeComponent(id)}'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return Announcement.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('update_announcement_failed');
  }

  Future<void> deleteAnnouncement(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/announcements/${Uri.encodeComponent(id)}'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('delete_announcement_failed');
    }
    PublicApiCache.instance.invalidate('/api/announcements');
  }

  /// Wpisy aktualności z WWW (`/aktualnosci`) — publiczna lista z API.
  Future<List<ClubPost>> getClubPosts() async {
    final response = await _getCachedPublic('/api/posts');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => ClubPost.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load club posts');
  }

  Future<ClubPost> getClubPost(String id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts/${Uri.encodeComponent(id)}'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return ClubPost.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load post');
  }

  /// Galeria klubu — opublikowane media.
  Future<List<GalleryPhoto>> getGalleryPhotos() async {
    final response = await _getCachedPublic('/api/gallery', ttl: const Duration(minutes: 5));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load gallery');
  }

  // Training Log
  Future<List<TrainingLogEntry>> getTrainingLog(String athleteId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/athletes/$athleteId/training-log'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => TrainingLogEntry.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load training log');
    }
  }

  Future<void> createTrainingLogEntry(
    String athleteId,
    String notes,
    String? title,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/athletes/$athleteId/training-log'),
      headers: _headers(token),
      body: jsonEncode({
        'notes': notes,
        'title': title,
        'session_date': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create entry');
    }
  }

  // SuperAdmin: Audit Logs
  Future<List<AuditLog>> getAuditLogs() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/system/audit-logs'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AuditLog.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load audit logs');
    }
  }

  // SuperAdmin: User Management
  Future<List<SlaviaUser>> getUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/admins'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => SlaviaUser.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Profile Update
  Future<void> updateProfile({
    String? avatarUrl,
    String? password,
    String? uiThemePreset,
    String? uiColorMode,
  }) async {
    final token = await getToken();
    final Map<String, String> body = {};
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (password != null) body['password'] = password;
    if (uiThemePreset != null) body['ui_theme_preset'] = uiThemePreset;
    if (uiColorMode != null) body['ui_color_mode'] = uiColorMode;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> updateMyAthleteProfile({
    int? birthYear,
    String? gender,
  }) async {
    final token = await getToken();
    final body = {
      if (birthYear != null) 'birth_year': birthYear,
      if (gender != null) 'gender': gender,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/api/athletes/me'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update athlete profile');
    }
  }

  // Athlete Results
  Future<List<CompetitionResult>> getAthleteResults(String athleteId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/results/athlete/$athleteId/submissions'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CompetitionResult.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load results');
    }
  }

  /// Historia startów (domyślnie zawody). `kind=training` — sala (wymaga uprawnień jak na WWW).
  Future<List<CompetitionResult>> getAthleteResultHistory(
    String athleteId, {
    String? kind,
  }) async {
    final token = await getToken();
    final q = (kind == null || kind.isEmpty)
        ? ''
        : '?kind=${Uri.encodeQueryComponent(kind)}';
    final response = await http.get(
      Uri.parse('$baseUrl/api/results/athlete/$athleteId$q'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CompetitionResult.fromJson(item)).toList();
    }
    throw Exception('Failed to load result history: ${response.statusCode}');
  }

  Future<void> submitResult({
    required String athleteId,
    required String date,
    required String kind,
    String? location,
    double? snatch,
    double? cleanAndJerk,
    required double total,
  }) async {
    final token = await getToken();
    final body = {
      'athlete_id': athleteId,
      'date': date,
      'kind': kind,
      'location': location,
      'snatch': snatch,
      'clean_and_jerk': cleanAndJerk,
      'total': total,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/results'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit result');
    }
  }

  // SuperAdmin: User Actions
  Future<void> createUser(
    String username,
    String password,
    List<String> roles,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/admins'),
      headers: _headers(token),
      body: jsonEncode({
        'username': username,
        'password': password,
        'roles': roles,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create user');
    }
  }

  Future<void> deleteUser(String userId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admins/$userId'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> updateUserRoles(String userId, List<String> roles) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admins/$userId/role'),
      headers: _headers(token),
      body: jsonEncode({'roles': roles}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update roles');
    }
  }

  // Athlete Management
  Future<void> createAthlete(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/athletes'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create athlete');
    }
  }

  Future<void> updateAthlete(String id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/athletes/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update athlete');
    }
  }

  Future<void> deleteAthlete(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/athletes/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete athlete');
    }
  }

  // Image Upload
  Future<String> uploadImage(File file, String purpose) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['purpose'] = purpose;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(
          'image',
          'jpeg',
        ), // Default to jpeg, picker usually provides it
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  /// Kadra — lista zawodników z `user_id` (jak `/api/athletes/admin` na WWW, m.in. do czatu).
  Future<List<Athlete>> getAthletesAdmin() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/athletes/admin'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Athlete.fromJson(item)).toList();
    }
    throw Exception('Failed to load admin athletes: ${response.statusCode}');
  }

  Future<List<ChatThread>> getChatThreads() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/threads'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load chat threads: ${response.statusCode}');
  }

  Future<ChatThread> openChatThread({
    required String athleteUserId,
    required String trainerUserId,
    String? title,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/threads'),
      headers: _headers(token),
      body: jsonEncode({
        'athlete_user_id': athleteUserId,
        'trainer_user_id': trainerUserId,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChatThread.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to open thread: ${response.body}');
  }

  Future<List<ChatMessage>> getChatMessages(String threadId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/chat/threads/${Uri.encodeComponent(threadId)}/messages',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  Future<void> pingChatPresence() async {
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/api/chat/presence'),
      headers: _headers(token),
    );
  }

  Future<List<ChatReactionSummary>> toggleChatReaction(
    String messageId,
    String emoji,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/chat/messages/${Uri.encodeComponent(messageId)}/reactions',
      ),
      headers: _headers(token),
      body: jsonEncode({'emoji': emoji}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => ChatReactionSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to toggle reaction: ${response.body}');
  }

  Future<void> sendChatMessage(String threadId, String body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/chat/threads/${Uri.encodeComponent(threadId)}/messages',
      ),
      headers: _headers(token),
      body: jsonEncode({'body': body}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<void> updateChatThreadTitle(String threadId, String title) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/chat/threads/${Uri.encodeComponent(threadId)}'),
      headers: _headers(token),
      body: jsonEncode({'title': title.trim().isEmpty ? null : title.trim()}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update title: ${response.body}');
    }
  }

  Future<void> deleteChatThread(String threadId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/chat/threads/${Uri.encodeComponent(threadId)}'),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete thread: ${response.body}');
    }
  }

  /// Chronologia wyników, obecności i wpisów dziennika (jak `/athlete/timeline` na WWW).
  Future<List<AthleteTimelineItem>> getAthleteTimeline(String athleteId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/athletes/${Uri.encodeComponent(athleteId)}/timeline',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (item) =>
                AthleteTimelineItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception('Failed to load athlete timeline');
  }

  /// Plany przypisane do zalogowanego profilu zawodnika (`GET /api/training-plans/my`).
  Future<List<TrainingPlan>> getMyTrainingPlans() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/training-plans/my'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => TrainingPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to load training plans: ${response.statusCode}');
  }

  Future<List<TrainingPlanItem>> getTrainingPlanItems(String planId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/training-plans/${Uri.encodeComponent(planId)}/items',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => TrainingPlanItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load plan items: ${response.statusCode}');
  }

  Future<void> patchMyTrainingPlanProgress(
    String planId, {
    required String status,
    required int progressPercent,
    required String athleteNote,
  }) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/api/training-plans/${Uri.encodeComponent(planId)}/my-progress',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'status': status,
        'progress_percent': progressPercent.clamp(0, 100),
        'athlete_note': athleteNote,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to save progress: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Kadra: plany wybranego zawodnika (`GET /api/training-plans/athlete/{id}`).
  Future<List<TrainingPlan>> getTrainingPlansForAthlete(String athleteId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/training-plans/athlete/${Uri.encodeComponent(athleteId)}',
      ),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => TrainingPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to load athlete plans: ${response.statusCode} ${response.body}',
    );
  }

  Future<TrainingPlan> createTrainingPlan({
    required String athleteId,
    required String title,
    String? goal,
    required String weekStart,
    String? status,
    String? coachNote,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{
      'athlete_id': athleteId,
      'title': title.trim(),
      'week_start': weekStart.trim(),
    };
    if (goal != null && goal.trim().isNotEmpty) {
      body['goal'] = goal.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      body['status'] = status.trim();
    }
    if (coachNote != null && coachNote.trim().isNotEmpty) {
      body['coach_note'] = coachNote.trim();
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/training-plans'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TrainingPlan.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'Failed to create plan: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> updateTrainingPlan(
    String planId, {
    required String title,
    String? goal,
    required String weekStart,
    required String status,
    String? coachNote,
  }) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/api/training-plans/${Uri.encodeComponent(planId)}',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'title': title.trim(),
        'week_start': weekStart.trim(),
        'status': status,
        'goal': (goal == null || goal.trim().isEmpty) ? null : goal.trim(),
        'coach_note': (coachNote == null || coachNote.trim().isEmpty)
            ? null
            : coachNote.trim(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update plan: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteTrainingPlan(String planId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/api/training-plans/${Uri.encodeComponent(planId)}',
      ),
      headers: _headers(token),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to delete plan: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> putTrainingPlanItems(
    String planId,
    List<PlanItemPutPayload> items,
  ) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/training-plans/${Uri.encodeComponent(planId)}/items',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to save plan items: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Exercise>> getExercises() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to load exercises: ${response.statusCode} ${response.body}',
    );
  }

  /// Kopia planu z jednostkami (jak `duplicatePlan` na `/trainer/plany`).
  Future<TrainingPlan> duplicateTrainingPlan({
    required TrainingPlan source,
    required String athleteId,
  }) async {
    final items = await getTrainingPlanItems(source.id);
    final created = await createTrainingPlan(
      athleteId: athleteId,
      title: '${source.title} (kopia)',
      goal: source.goal,
      weekStart: source.weekStart,
      status: source.status,
      coachNote: source.coachNote,
    );
    final payloads = items
        .map(
          (i) => PlanItemPutPayload(
            dayOfWeek: i.dayOfWeek,
            exerciseId: i.exerciseId,
            customExerciseName: i.customExerciseName ?? '',
            sets: i.sets,
            reps: i.reps,
            intensityPercent: i.intensityPercent,
            weightKg: i.weightKg,
            notes: i.notes ?? '',
            sortOrder: i.sortOrder,
          ),
        )
        .toList();
    await putTrainingPlanItems(created.id, payloads);
    return created;
  }

  /// Dziennik regeneracji zawodnika (`GET /api/recovery`).
  Future<List<RecoveryLog>> getMyRecoveryLogs() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/recovery'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => RecoveryLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to load recovery logs: ${response.statusCode} ${response.body}',
    );
  }

  Future<RecoveryLog> upsertMyRecoveryLog({
    required String date,
    required double sleepHours,
    required int fatigueLevel,
    required int sorenessLevel,
    required int readinessLevel,
    String? note,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{
      'date': date.trim(),
      'sleep_hours': sleepHours.clamp(0.0, 24.0),
      'fatigue_level': fatigueLevel.clamp(1, 10),
      'soreness_level': sorenessLevel.clamp(1, 10),
      'readiness_level': readinessLevel.clamp(1, 10),
    };
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/recovery'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return RecoveryLog.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'Failed to save recovery log: ${response.statusCode} ${response.body}',
    );
  }

  // Payments
  Future<PaymentStatusResponse> getMyPaymentStatus({String? month}) async {
    final token = await getToken();
    final q = month == null ? '' : '?month=${Uri.encodeQueryComponent(month)}';
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/my/status$q'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return PaymentStatusResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load payment status');
  }

  Future<List<PaymentMonthStatusRow>> getMyPaymentsYear({int? year}) async {
    final token = await getToken();
    final q = year == null ? '' : '?year=$year';
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/my/year$q'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PaymentMonthStatusRow.fromJson(e)).toList();
    }
    throw Exception('Failed to load yearly payments');
  }

  Future<void> createMyPayment({
    String? month,
    double? amountPln,
    String? note,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/payments/my'),
      headers: _headers(token),
      body: jsonEncode({
        if (month != null) 'month': month,
        if (amountPln != null) 'amount_pln': amountPln,
        if (note != null) 'note': note,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit payment: ${response.body}');
    }
  }

  Future<void> upsertAttendance({
    required String athleteId,
    required String sessionDate,
    required String status,
    String? note,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance'),
      headers: _headers(token),
      body: jsonEncode({
        'athlete_id': athleteId,
        'session_date': sessionDate,
        'status': status,
        if (note != null) 'note': note,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upsert attendance: ${response.body}');
    }
  }
}

class AuditLog {
  final String id;
  final String? actorUsername;
  final String? actorRole;
  final String category;
  final String action;
  final String? targetType;
  final String? details;
  final String createdAt;

  AuditLog({
    required this.id,
    this.actorUsername,
    this.actorRole,
    required this.category,
    required this.action,
    this.targetType,
    this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      actorUsername: json['actor_username'],
      actorRole: json['actor_role'],
      category: json['category'],
      action: json['action'],
      targetType: json['target_type'],
      details: json['details'],
      createdAt: json['created_at'],
    );
  }
}

class SlaviaUser {
  final String id;
  final String username;
  final String? email;
  final List<String> roles;
  final String? athleteId;

  SlaviaUser({
    required this.id,
    required this.username,
    this.email,
    required this.roles,
    this.athleteId,
  });

  factory SlaviaUser.fromJson(Map<String, dynamic> json) {
    return SlaviaUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      roles: List<String>.from(json['roles']),
      athleteId: json['athlete_id'],
    );
  }
}
