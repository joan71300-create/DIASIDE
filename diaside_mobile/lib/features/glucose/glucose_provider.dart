import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glucose_model.dart';

class GlucoseNotifier extends StateNotifier<List<GlucoseEntry>> {
  GlucoseNotifier() : super([]);
  final _dio = Dio();

  Future<void> addEntry(double value, String? note) async {
    final newEntry = GlucoseEntry(value: value, timestamp: DateTime.now());
    state = [...state, newEntry];

    try {
      // Envoi de la valeur au serveur Python local
      final response = await _dio.post(
        'http://127.0.0.1:8000/analyze',
        data: {'value': value},
      );
      print("Analyse reçue : ${response.data['analysis']}");
    } catch (e) {
      print("Erreur de connexion au serveur : $e");
    }
  }
}

final glucoseProvider =
    StateNotifierProvider<GlucoseNotifier, List<GlucoseEntry>>((ref) {
      return GlucoseNotifier();
    });
