import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diaside_mobile/core/constants/api_constants.dart';
import 'models/health_profile.dart';

/// Provider pour le profil santé
class HealthProfileNotifier extends StateNotifier<HealthProfile?> {
  HealthProfileNotifier() : super(null) {
    _loadProfile();
  }

  final _storage = const FlutterSecureStorage();
  final _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<void> _loadProfile() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await _dio.get(
        '/api/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 200 && response.data != null) {
        state = HealthProfile.fromJson(response.data);
      }
    } catch (e) {
      print("Erreur chargement profil: $e");
    }
  }

  Future<bool> updateProfile(HealthProfile profile) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      final response = await _dio.put(
        '/api/profile',
        data: profile.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 200) {
        state = profile;
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur mise à jour profil: $e");
      return false;
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

final healthProfileProvider = StateNotifierProvider<HealthProfileNotifier, HealthProfile?>((ref) {
  return HealthProfileNotifier();
});
