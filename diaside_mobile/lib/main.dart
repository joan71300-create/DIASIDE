import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/glucose/screens/medtrum_connect_screen.dart'; // Added this import
import 'shared/screens/main_navigation_screen.dart';
import 'shared/screens/splash_screen.dart';

void main() {
  // 1. Initialisation minimale pour Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ON NE BLOQUE PAS LE MAIN.
  // On lance l'application tout de suite.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isLoading = true;
  String? _initialToken;

  @override
  void initState() {
    super.initState();
    // 3. On lance l'initialisation une fois que le premier rendu est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAllServices();
    });
  }

  Future<void> _startAllServices() async {
    try {
      // Un micro-délai pour laisser le thread UI respirer et afficher le Splash
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Initialisations lourdes faites en parallèle pendant que le Splash tourne
      await Future.wait([_initFirebase(), _initEnv()]);

      // 5. Restauration de la session (on baisse le timeout à 5s pour plus de réactivité)
      _initialToken = await authService.restoreSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      print("⚠️ Erreur au démarrage: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  }

  Future<void> _initEnv() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIASIDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 6. On force une couleur de fond blanche au niveau du MaterialApp
      // pour éviter l'écran noir si le moteur Flutter rame.
      color: Colors.white,
      builder: (context, child) {
        return Container(
          color: Colors.white, // Sécurité anti-écran noir
          child: child,
        );
      },
      home: _isLoading
          ? const SplashScreen()
          : (_initialToken != null
                ? const MainNavigationScreen()
                : const LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/medtrum': (context) => const MedtrumConnectScreen(), // Added this route
      },
    );
  }
}
