import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// StateProvider pour stocker le accessToken
final accessTokenProvider = StateProvider<String?>((ref) => null);

// Fonction pour se connecter
Future<bool> login(String email, String password, WidgetRef ref) async {
  final success = await authService.login(email, password);
  if (success) {
    final token = await authService.getToken();
    ref.read(accessTokenProvider.notifier).state = token;
  }
  return success;
}

// Fonction pour se connecter avec Google
Future<bool> loginWithGoogle(WidgetRef ref) async {
  final success = await authService.signInWithGoogle();
  if (success) {
    final token = await authService.getToken();
    ref.read(accessTokenProvider.notifier).state = token;
  }
  return success;
}

// Fonction pour s'inscrire
Future<String?> register(String email, String password, WidgetRef ref) async {
  return await authService.register(email, password);
}

// Fonction pour se déconnecter
Future<void> logout(WidgetRef ref) async {
  await authService.logout();
  ref.read(accessTokenProvider.notifier).state = null;
}
