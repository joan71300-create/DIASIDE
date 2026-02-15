import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // URL du backend Render en production
  static const String _renderUrl = 'https://diaside-backend.onrender.com';
  
  // URL locale pour développement
  static const String _localUrl = 'http://10.0.2.2:8000';
  
  static String get baseUrl {
    // En production (vrai téléphone ou web), utiliser Render
    return _renderUrl;
  }
  
  // Alias pour compatibilité
  static String get apiBaseUrl => baseUrl;
}
