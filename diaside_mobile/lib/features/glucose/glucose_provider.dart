import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glucose_model.dart';
import '../auth/providers/auth_provider.dart';

class GlucoseNotifier extends StateNotifier<List<GlucoseEntry>> {
  GlucoseNotifier(this.ref) : super([]);
  final Ref ref;
  final _dio = Dio();

  String _generateRequestId() {
    final random = Random();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> addEntry(double value, String? note) async {
    final newEntry = GlucoseEntry(value: value, timestamp: DateTime.now(), note: note);
    state = [...state, newEntry];

    try {
      final token = ref.watch(accessTokenProvider);
      final requestId = _generateRequestId();

      if (token == null) {
        print("Erreur: Pas de token, l'utilisateur n'est pas connecté.");
        return;
      }

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/ai/coach',
        data: {'value': value, 'note': note},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "X-Request-ID": requestId,
          },
        ),
      );

      print("Analyse reçue ($requestId): ${response.data['analysis']}");

      final analysis = response.data['analysis'];
      state = state.map((entry) {
        if (entry == newEntry) {
          return entry.copyWith(analysis: analysis);
        }
        return entry;
      }).toList();
    } catch (e) {
      if (e is DioException) {
        print("Erreur API (${e.response?.statusCode}): ${e.response?.data}");
      } else {
        print("Erreur de connexion : $e");
      }
    }
  }
}

final glucoseProvider =
    StateNotifierProvider<GlucoseNotifier, List<GlucoseEntry>>((ref) {
      return GlucoseNotifier(ref);
    });
