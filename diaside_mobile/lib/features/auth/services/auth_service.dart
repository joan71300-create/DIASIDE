import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:diaside_mobile/core/constants/api_constants.dart'; // Import ApiConfig

// Removed: import 'dart:io';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService() {
    // Use ApiConfig.baseUrl as the default URL
    final baseUrl = ApiConfig.baseUrl;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // Annulé par l'utilisateur

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        return await _authenticateWithBackend(idToken);
      }
      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return false;
    }
  }

  /// Email/Password Login (Firebase)
  Future<String?> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null) {
        final success = await _authenticateWithBackend(idToken);
        return success ? null : "Échec synchronisation Backend (Vérifiez logs)";
      }
      return "Erreur Token Firebase (Null)";
    } catch (e) {
      print('Login error: $e');
      return e.toString();
    }
  }

  /// Email/Password Register (Firebase)
  Future<String?> register(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      // On peut envoyer un email de vérification ici : userCredential.user?.sendEmailVerification();
      
      // Après inscription, on connecte automatiquement
      return await login(email, password);
    } catch (e) {
      print('Register error: $e');
      return e.toString();
    }
  }

  /// Échange le token Firebase contre une session Backend (si nécessaire)
  /// Ou envoie juste le token pour créer l'utilisateur en base
  Future<bool> _authenticateWithBackend(String firebaseIdToken) async {
    try {
      // On envoie le token Firebase au backend pour validation et création du User
      final response = await _dio.post('/auth/firebase-login', data: {
        'id_token': firebaseIdToken,
      });

      if (response.statusCode == 200) {
        // Le backend nous renvoie son propre token (ou on garde celui de Firebase)
        // Ici on suppose que le backend renvoie un JWT "App" pour la session
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];
        
        await _storage.write(key: 'jwt_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Backend Sync Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getToken() async {
    // On peut renvoyer le token stocké, ou rafraîchir le token Firebase si besoin
    return await _storage.read(key: 'jwt_token');
  }

  /// Restaure la session : vérifie le token Backend ou le rafraîchit via Firebase
  Future<String?> restoreSession() async {
    String? token = await _storage.read(key: 'jwt_token');
    
    // Si on a un user Firebase mais pas de token (ou on veut être sûr), on sync
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken(true); // Force refresh
        if (idToken != null) {
          final success = await _authenticateWithBackend(idToken);
          if (success) {
            token = await _storage.read(key: 'jwt_token');
          }
        }
      } catch (e) {
        print("Session Restore Error: $e");
      }
    }
    return token;
  }
}

final authService = AuthService();