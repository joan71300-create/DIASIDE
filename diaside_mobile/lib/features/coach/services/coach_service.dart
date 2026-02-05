import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coach_models.dart';
import 'dart:io';

class CoachService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000',
      connectTimeout: const Duration(seconds: 15), // Gemini can be slow
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final _storage = const FlutterSecureStorage();

  Future<CoachResponse?> getAdvice({
    required UserHealthSnapshot snapshot,
    List<ChatMessage> history = const [],
    String? userMessage,
    String? imageBase64,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("No token found");

      final requestBody = ChatRequest(
        snapshot: snapshot,
        history: history,
        userMessage: userMessage,
        imageBase64: imageBase64,
      ).toJson();

      final response = await _dio.post(
        '/api/ai/coach',
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return CoachResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Coach API error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          throw Exception("Conseil bloqué par sécurité.");
        }
      }
      rethrow;
    }
  }

  Future<void> logActivity(DailyStats stats) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("No token found");

      await _dio.post(
        '/api/log/activity',
        data: stats.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Log Activity Error: $e');
      rethrow;
    }
  }

  Future<void> logMeal(Meal meal) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("No token found");

      await _dio.post(
        '/api/log/meal',
        data: meal.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Log Meal Error: $e');
      rethrow;
    }
  }
}

final coachService = CoachService();
