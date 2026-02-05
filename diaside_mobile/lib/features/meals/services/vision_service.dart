import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

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
      description: json['description'] ?? "Repas détecté",
      carbs: json['carbs'] ?? 0,
      calories: json['calories'] ?? 0,
      advice: json['advice'] ?? "",
    );
  }
}

class VisionService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));

  Future<FoodAnalysis> analyzeFood(File imageFile) async {
    // Simulation d'appel API pour le moment
    await Future.delayed(const Duration(seconds: 2));
    
    // Dans une version réelle, on enverrait le multipart
    /*
    String fileName = imageFile.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imageFile.path, filename:fileName),
    });
    final response = await _dio.post("/api/vision/analyze", data: formData);
    return FoodAnalysis.fromJson(response.data);
    */

    return FoodAnalysis(
      description: "Poulet grillé et Riz",
      carbs: 45,
      calories: 520,
      advice: "Une marche de 15 minutes est recommandée après ce repas.",
    );
  }
}

final visionServiceProvider = Provider((ref) => VisionService());