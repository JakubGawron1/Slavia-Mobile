import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'public_api_cache.dart';

/// Publiczne rozszerzenia API — ranking, wyzwania, flagi panelu.
extension ApiServicePublicExt on ApiService {
  Future<List<Map<String, dynamic>>> getSinclairRanking({
    bool forceRefresh = false,
  }) async {
    const path = '/api/athletes/ranking/sinclair';
    if (forceRefresh) {
      PublicApiCache.instance.invalidate(path);
    }
    final response = await http.get(Uri.parse('${ApiService.baseUrl}$path'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load Sinclair ranking');
  }

  Future<Map<String, dynamic>> getMonthlyChallengeLeaderboard({
    String? month,
    String metric = 'sessions',
  }) async {
    final query = <String, String>{'metric': metric};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }
    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/challenges/monthly-training-sessions',
    ).replace(queryParameters: query);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load challenge leaderboard');
  }

  Future<List<Map<String, dynamic>>> getFeatureFlags() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/feature-flags'),
      headers: _publicExtHeaders(token),
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load feature flags');
  }
}

Map<String, String> _publicExtHeaders(String? token) {
  final headers = {'Content-Type': 'application/json'};
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
