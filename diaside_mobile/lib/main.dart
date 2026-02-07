import 'features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import added
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'shared/screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print(
      "⚠️ Firebase initialization failed (Missing google-services.json?): $e",
    );
  }

  await dotenv.load(fileName: ".env");

  String? token;
  try {
    // Timeout added to prevent black screen if secure storage hangs
    token = await authService.getToken().timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
  } catch (e) {
    print("⚠️ Error reading token: $e");
    token = null;
  }

  runApp(
    ProviderScope(
      overrides: [accessTokenProvider.overrideWith((ref) => token)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(accessTokenProvider);

    return MaterialApp(
      title: 'DIASIDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: token != null ? const MainNavigationScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}
