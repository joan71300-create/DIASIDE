import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProfileService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ProfileService() {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:8000';
    } else {
      baseUrl = 'http://127.0.0.1:8000';
    }
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      final response = await _dio.get(
        '/api/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print("Get Profile Error: $e");
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      await _dio.put(
        '/api/profile',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      print("Update Profile Error: $e");
      return false;
    }
  }
}

final profileService = ProfileService();
