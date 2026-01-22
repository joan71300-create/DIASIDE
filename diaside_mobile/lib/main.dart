import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/glucose/glucose_screen.dart'; // Nous allons créer ce fichier juste après

void main() {
  // ProviderScope est obligatoire pour utiliser Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIASIDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // On lance directement l'écran de saisie de glucose
      home: const GlucoseInputScreen(),
    );
  }
}
