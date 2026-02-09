import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

// Conditional imports for dart:io and dart:typed_data
import 'dart:io' if (dart.library.html) 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MealState {
  final bool isLoading;
  final String? advice;
  final int? carbs;
  final String? error;
  final XFile? selectedImage; // Changed from File? to XFile?

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
    XFile? selectedImage, // Changed from File? to XFile?
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
  late final Dio _dio;
  
  MealNotifier() : super(MealState()) {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://127.0.0.1:8000';
    } else { // Simplified baseUrl logic to remove Platform.isAndroid
      baseUrl = 'http://127.0.0.1:8000'; // Default for non-web, including Android
    }
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
  }

  final _picker = ImagePicker();
  final _storage = const FlutterSecureStorage();

  Future<void> pickAndAnalyzeImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    
    if (photo == null) return;

    state = state.copyWith(isLoading: true, selectedImage: photo, error: null); // Store XFile directly

    try {
      final token = await _storage.read(key: 'jwt_token');
      
      // Multipart upload
      String fileName = photo.name; // Use photo.name for filename
      FormData formData;

      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(photo.path, filename: fileName),
        });
      }

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