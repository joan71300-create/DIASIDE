import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Correction de l'URL pour le Web
  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000'; // Localhost pour le Web
    if (Platform.isAndroid) return 'http://10.0.2.2:8000'; // Émulateur Android
    return 'http://127.0.0.1:8000'; // iOS / Desktop
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 60), // Increased from 10s
        receiveTimeout: const Duration(seconds: 300), // Increased to 5min for heavy sync
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
  Future<bool> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null) {
        return await _authenticateWithBackend(idToken);
      }
      return false;
    } catch (e) {
      print('Firebase Login error: $e');
      return false;
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
      return await login(email, password) ? null : "Erreur lors de la connexion post-inscription";
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
}

final authService = AuthService();
