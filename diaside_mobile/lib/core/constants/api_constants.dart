import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Changed from localhost to 127.0.0.1 for web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';   // Pour l'émulateur
    } else {
      return 'http://127.0.0.1:8000'; // Pour iOS ou Desktop
    }
  }
}
