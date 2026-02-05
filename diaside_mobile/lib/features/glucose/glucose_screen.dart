import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'glucose_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/diaside_card.dart';
import '../../shared/widgets/diaside_button.dart';
import 'screens/medtrum_connect_screen.dart';

class GlucoseInputScreen extends ConsumerWidget {
  const GlucoseInputScreen({super.key});

  Future<void> _importPDF(BuildContext context, WidgetRef ref) async {
    // 1. Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      // 2. Show Simulated Analysis Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text("Analyse IA du rapport PDF...", style: GoogleFonts.poppins()),
              Text("Extraction des données Medtrum (90 jours)", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      // 3. Wait 3 seconds (Simulate IA OCR)
      await Future.delayed(const Duration(seconds: 3));

      // 4. Success !
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Rapport importé ! HbA1c mise à jour."),
          )
        );
      }
      
      // Refresh logic (trigger refetch)
      ref.invalidate(glucoseProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final glucoseEntries = ref.watch(glucoseProvider).reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('JOURNAL GLYCÉMIQUE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: "Importer Rapport",
            onPressed: () => _importPDF(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primary),
            tooltip: "Connexion Medtrum",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const MedtrumConnectScreen())
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Medtrum Banner
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedtrumConnectScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: AppColors.primaryLight.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text("Connexion Medtrum", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          
          // Input Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.background,
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Nouvelle mesure",
                    hintText: "0.0",
                    suffixText: "mg/dL",
                    prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                DiasideButton(
                  label: "Enregistrer",
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null) {
                      ref.read(glucoseProvider.notifier).addEntry(val, "Saisie manuelle");
                      controller.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // History Section
          Expanded(
            child: glucoseEntries.isEmpty 
              ? Center(child: Text("Aucun historique", style: GoogleFonts.poppins(color: AppColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: glucoseEntries.length,
                  itemBuilder: (context, index) {
                    final entry = glucoseEntries[index];
                    return DiasideCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.water_drop, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${entry.value.toInt()} mg/dL",
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text(
                                  "${entry.timestamp.hour}h${entry.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (entry.analysis != null) Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    entry.analysis!,
                                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
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