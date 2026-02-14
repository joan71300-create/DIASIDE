import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // URL du backend Render en production
  static const String _renderUrl = 'https://diaside-backend.onrender.com';
  
  // URL locale pour développement
  static const String _localUrl = 'http://10.0.2.2:8000';
  
  static String get baseUrl {
    // En production (web déployé), utiliser Render
    if (kIsWeb) {
      return _renderUrl;
    }
    // En développement sur émulateur Android
    else if (Platform.isAndroid) {
      return _localUrl;
    }
    // Pour iOS Simulator ou Desktop
    else {
      return _localUrl;
    }
  }
  
  // Alias pour compatibilité
  static String get apiBaseUrl => baseUrl;
}
