import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Use the Render.com backend URL for web deployment
      return 'https://diaside-backend.onrender.com';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';   // Pour l'émulateur
    } else {
      return 'http://127.0.0.1:8000'; // Pour iOS ou Desktop
    }
  }
}
