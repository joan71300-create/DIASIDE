import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// L'import fonctionnera une fois les fichiers déplacés
import 'glucose_provider.dart';

class GlucoseInputScreen extends ConsumerWidget {
  const GlucoseInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    // Watch écoute les changements dans la liste des mesures
    final glucoseEntries = ref.watch(glucoseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIASIDE - Suivi Glycémique'),
        // Correction de la dépréciation : withValues au lieu de withOpacity
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Taux de glucose (mg/dL)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null) {
                      ref
                          .read(glucoseProvider.notifier)
                          .addEntry(val, "Saisie manuelle");
                      controller.clear();
                    }
                  },
                  child: const Text("Ajouter"),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: glucoseEntries.length,
              itemBuilder: (context, index) {
                final entry = glucoseEntries[index];
                return ListTile(
                  leading: const Icon(Icons.bloodtype, color: Colors.red),
                  title: Text("${entry.value} mg/dL"),
                  subtitle: Text(
                    "${entry.timestamp.hour}h${entry.timestamp.minute}",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
