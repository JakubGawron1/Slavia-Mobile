import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Trener AI — wydzielone z monolitu `api_service.dart` (Fala 3).
extension ApiServiceAiCoach on ApiService {
  Future<Map<String, dynamic>> getAiCoachStatus() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/ai/coach/status'),
      headers: _aiCoachHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load AI coach status');
  }

  Future<String> sendAiCoachChat({
    required String message,
    String mode = 'chat',
    List<Map<String, String>> history = const [],
    String? athleteId,
    bool? useAthleteContext,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{
      'message': message,
      'mode': mode,
      'history': history,
      'athlete_id': ?athleteId,
      'use_athlete_context': ?useAthleteContext,
    };
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/ai/coach/chat'),
      headers: _aiCoachHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['reply'] as String?) ?? '';
    }
    throw Exception('AI coach chat failed: ${response.body}');
  }
}

Map<String, String> _aiCoachHeaders(String? token) {
  final headers = {'Content-Type': 'application/json'};
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
