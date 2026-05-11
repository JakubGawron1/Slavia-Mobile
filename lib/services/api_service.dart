import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth.dart';
import '../models/athlete.dart';
import '../models/notification.dart';
import '../models/competition.dart';
import '../models/announcement.dart';
import '../models/chat.dart';

class ApiService {
  static const String baseUrl = 'https://slavia-backend.onrender.com';
  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('auth_token');
    } else {
      await prefs.setString('auth_token', token);
    }
  }

  Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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
      return AuthUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user data');
    }
  }

  // Athletes
  Future<List<Athlete>> getAthletes() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/athletes'),
      headers: _headers(token),
    );

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

  // Announcements
  Future<List<Announcement>> getAnnouncements() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/announcements'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Announcement.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load announcements');
    }
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
  Future<void> updateProfile({String? avatarUrl, String? password}) async {
    final token = await getToken();
    final Map<String, String> body = {};
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (password != null) body['password'] = password;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
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
