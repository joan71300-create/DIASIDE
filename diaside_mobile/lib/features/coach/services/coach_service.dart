import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coach_models.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
// Removed: import 'dart:io';
import 'package:diaside_mobile/core/constants/api_constants.dart'; // Import ApiConfig

class CoachService {
  late final Dio _dio; // Declare Dio here
  final _storage = const FlutterSecureStorage();

  CoachService() {
    // Initialize Dio with ApiConfig.baseUrl
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl, // Use the centralized ApiConfig
        connectTimeout: const Duration(seconds: 30), // Increased for production
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

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

  Future<FoodRecognitionResponse> analyzeFoodImage(Map<String, dynamic> requestJson) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("No token found");

      // Use JSON endpoint with base64
      final response = await _dio.post(
        '/api/vision/food/base64',
        data: requestJson,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return FoodRecognitionResponse.fromJson(response.data);
      }
      throw Exception("Failed to analyze food image");
    } catch (e) {
      print('Analyze Food Image Error: $e');
      rethrow;
    }
  }
}

final coachService = CoachService();