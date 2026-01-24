import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000', // Retour au port 8000
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });
      final response = await _dio.post('/auth/login', data: formData);

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return null; // Pas d'erreur
      }
      return "Erreur inconnue";
    } catch (e) {
      print('Register error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return "Cet email est déjà utilisé.";
        }
        return "Erreur serveur (${e.response?.statusCode})";
      }
      return "Erreur de connexion";
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}

final authService = AuthService();
