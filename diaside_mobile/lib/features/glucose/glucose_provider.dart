import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'glucose_model.dart';

class GlucoseNotifier extends StateNotifier<List<GlucoseEntry>> {
  GlucoseNotifier(this.ref) : super([]) {
    fetchHistory();
  }
  
  final Ref ref;
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<void> fetchHistory() async {
    try {
      _initDio();
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await _dio.get(
        '/api/history', 
        queryParameters: {'limit': 200}, // Optimisation: Réduit de 1000 à 200 pour éviter le lag UI
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 200) {
      final List<dynamic> data = response.data as List<dynamic>;
      final List<GlucoseEntry> parsedEntries = data.where((json) {
        // Ensure essential fields are present and not null
        return json['value'] != null &&
               json['timestamp'] != null &&
               json['value'] is num &&
               json['timestamp'] is String;
      }).map((json) {
        // Safely parse known good entries
        return GlucoseEntry.fromJson(json);
      }).toList();
      state = parsedEntries;
      }
    } catch (e) {
      print("Erreur fetchHistory: $e");
    }
  }

  Future<void> addEntry(double value, String? note) async {
    final newEntry = GlucoseEntry(value: value, timestamp: DateTime.now(), note: note);
    state = [...state, newEntry];
    // TODO: Send to API
  }
}

final glucoseProvider = StateNotifierProvider<GlucoseNotifier, List<GlucoseEntry>>((ref) {
  return GlucoseNotifier(ref);
});

// Provider pour l'offset HbA1c (Stocké localement)
final hba1cOffsetProvider = StateProvider<double>((ref) => 0.0);