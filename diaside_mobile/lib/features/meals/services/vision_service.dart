import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:dio/dio.dart";
import "dart:typed_data";
import "package:flutter_secure_storage/flutter_secure_storage.dart"; // Import FlutterSecureStorage

class FoodAnalysis {
  final String description;
  final int carbs;
  final int calories;
  final String advice;

  FoodAnalysis({
    required this.description,
    required this.carbs,
    required this.calories,
    required this.advice,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      description: json["description"] ?? "Repas détecté",
      carbs: json["carbs"] ?? 0,
      calories: json["calories"] ?? 0,
      advice: json["advice"] ?? "",
    );
  }
}

class VisionService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage(); // Initialize storage

  VisionService() {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = "http://127.0.0.1:8000";
    } else if (kIsWeb) {
      baseUrl = "http://10.0.2.2:8000";
    } else {
      baseUrl = "http://127.0.0.1:8000";
    }
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
  }

  Future<FoodAnalysis> analyzeFood(dynamic image, String fileName, double currentGlucose, String glucoseTrend) async {
    if (image == null) {
      throw Exception("Image data is null.");
    }

    final token = await _storage.read(key: "jwt_token"); // Get token
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    FormData formData = FormData.fromMap({
      "image": kIsWeb // Changed key from "file" to "image"
          ? MultipartFile.fromBytes(image as List<int>, filename: fileName)
          : await MultipartFile.fromFile(image.path, filename: fileName),
      "current_glucose": currentGlucose,
      "trend": glucoseTrend,
    });

    print("DEBUG (Frontend VisionService): Sending FormData: ${formData.fields}"); // DEBUG PRINT
    print("DEBUG (Frontend VisionService): Sending FormData files: ${formData.files}"); // DEBUG PRINT

    final response = await _dio.post(
      "/api/vision/food", 
      data: formData,
      options: Options(headers: {"Authorization": "Bearer $token"}), // Add Authorization header
    );
    return FoodAnalysis.fromJson(response.data);
  }
}

final visionServiceProvider = Provider((ref) => VisionService());
