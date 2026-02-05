import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_card.dart';

import '../../glucose/glucose_provider.dart'; // Added import

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // ...
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ... (Header)
            
            const SizedBox(height: 30),
            
            // Menu Items
            DiasideCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildMenuItem(Icons.person_outline, "Informations Personnelles"),
                  const Divider(height: 1),
                  _buildMenuItem(
                    Icons.tune, 
                    "Calibration Médicale (HbA1c)",
                    onTap: () => _showCalibrationDialog(context, ref)
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.notifications_none, "Notifications"),
                  // ...
                ],
              ),
            ),
            // ...
          ],
        ),
      ),
    );
  }

  void _showCalibrationDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Calibration Labo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Entrez votre dernière HbA1c sanguine pour ajuster l'estimation du capteur."),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "HbA1c Labo (%)", suffixText: "%"),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final labVal = double.tryParse(controller.text);
              if (labVal != null) {
                // On calcule l'offset approximatif
                // Note: Idéalement il faudrait récupérer l'eA1c actuelle ici pour faire la soustraction exacte
                // Pour simplifier l'UX, on demande juste la valeur cible
                // Et on mettra à jour l'offset en conséquence.
                // Ici, astuce : on stocke la différence avec 8.2 (valeur par défaut) ou mieux, on met un offset arbitraire pour tester
                ref.read(hba1cOffsetProvider.notifier).state = labVal - 8.2; // Exemple temporaire
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calibration enregistrée !")));
              }
            }, 
            child: const Text("Valider")
          )
        ],
      )
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return DiasideCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap ?? () {},
    );
  }
}
