import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../exceptions/battle_api_exception.dart';
import '../models/api_responses.dart';

class BattleRepository {
  final String baseUrl;
  final FirebaseAuth auth;

  BattleRepository({
    required this.baseUrl,
    required this.auth,
  });

  Future<String> _getToken() async {
    final user = auth.currentUser;
    if (user == null) {
      throw BattleApiException(code: 'unauthorized', message: 'User is not logged in.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw BattleApiException(code: 'unauthorized', message: 'Could not retrieve ID token.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> responseData = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }
      } catch (_) {
        // Ignored if response is not valid JSON
      }
    }

    if (response.statusCode >= 400) {
      throw BattleApiException.fromJson(responseData);
    }

    return responseData;
  }

  Future<dynamic> _get(String endpoint) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      if (responseData is Map<String, dynamic>) {
        throw BattleApiException.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch: ${response.statusCode}');
      }
    }

    return responseData;
  }

  Future<CreateBattleResponse> createBattle({
    required String topicId,
    required int questionCount,
    required int timeLimitSeconds,
    required int maxPlayers,
  }) async {
    final data = await _post('/battle/create', {
      'topicId': topicId,
      'questionCount': questionCount,
      'timeLimitSeconds': timeLimitSeconds,
      'maxPlayers': maxPlayers,
    });
    return CreateBattleResponse.fromJson(data);
  }

  Future<JoinBattleResponse> joinBattle({required String code}) async {
    final data = await _post('/battle/join', {'code': code});
    return JoinBattleResponse.fromJson(data);
  }

  Future<void> toggleReady({required String code, required bool isReady}) async {
    await _post('/battle/toggle-ready', {'code': code, 'isReady': isReady});
  }

  Future<void> startBattle({required String code}) async {
    await _post('/battle/start', {'code': code});
  }

  Future<void> submitAllAnswers({
    required String code,
    required List<Map<String, dynamic>> answers,
  }) async {
    int retries = 3;
    while (retries > 0) {
      try {
        await _post('/battle/submit-all', {
          'code': code,
          'answers': answers,
        });
        return; // Success
      } catch (e) {
        retries--;
        if (retries == 0) rethrow; // Bubble up if out of retries
        await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
      }
    }
  }

  Future<void> leaveBattle({required String code}) async {
    await _post('/battle/leave', {'code': code});
  }

  Future<List<Map<String, dynamic>>> getBattleQuestions({required String code}) async {
    final data = await _get('/battle/$code/questions');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
