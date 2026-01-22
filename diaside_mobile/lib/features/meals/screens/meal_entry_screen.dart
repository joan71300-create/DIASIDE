import 'package:flutter/material.dart';

class MealEntryScreen extends StatelessWidget {
  const MealEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Repas")),
      body: ListView(
        children: const [
          SizedBox(height: 20),
          Center(child: Text("Saisie des repas bientôt disponible")),
        ],
      ),
    );
  }
}
