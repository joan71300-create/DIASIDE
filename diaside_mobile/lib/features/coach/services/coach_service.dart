import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coach_models.dart';

class CoachService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000',
      connectTimeout: const Duration(seconds: 15), // Gemini can be slow
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final _storage = const FlutterSecureStorage();

  Future<CoachResponse?> getAdvice(UserHealthSnapshot snapshot) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("No token found");

      final response = await _dio.post(
        '/api/ai/coach',
        data: snapshot.toJson(),
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
}

final coachService = CoachService();
