import 'package:flutter/material.dart';
import '../widgets/medtrum_monitor.dart';

class MedtrumWebviewScreen extends StatelessWidget {
  const MedtrumWebviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moniteur Medtrum (Live)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Connexion directe à EasyView",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Le Moniteur prend tout l'espace restant
            Expanded(
              child: MedtrumMonitor(
                // Si l'URL change, modifier ici.
                // targetUrl: "https://my.glookoxt.com/dashboard", 
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Note: Vous devrez vous connecter lors de la première utilisation.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
