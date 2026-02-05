import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MealState {
  final bool isLoading;
  final String? advice;
  final int? carbs;
  final String? error;
  final File? selectedImage;

  MealState({
    this.isLoading = false,
    this.advice,
    this.carbs,
    this.error,
    this.selectedImage,
  });

  MealState copyWith({
    bool? isLoading,
    String? advice,
    int? carbs,
    String? error,
    File? selectedImage,
  }) {
    return MealState(
      isLoading: isLoading ?? this.isLoading,
      advice: advice ?? this.advice,
      carbs: carbs ?? this.carbs,
      error: error,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class MealNotifier extends StateNotifier<MealState> {
  MealNotifier() : super(MealState());

  final _picker = ImagePicker();
  final _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
  final _storage = const FlutterSecureStorage();

  Future<void> pickAndAnalyzeImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    
    if (photo == null) return;

    state = state.copyWith(isLoading: true, selectedImage: File(photo.path), error: null);

    try {
      final token = await _storage.read(key: 'jwt_token');
      
      // Multipart upload
      String fileName = photo.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(photo.path, filename: fileName),
      });

      final response = await _dio.post(
        '/api/vision/analyze',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoading: false,
          advice: response.data['advice'],
          carbs: response.data['carbs'],
        );
      }
    } catch (e) {
      print('Vision API Error: $e');
      state = state.copyWith(isLoading: false, error: "Erreur d'analyse : ${e.toString()}");
    }
  }
}

final mealProvider = StateNotifierProvider<MealNotifier, MealState>((ref) {
  return MealNotifier();
});
