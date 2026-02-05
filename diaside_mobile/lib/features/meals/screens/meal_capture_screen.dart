import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/vision_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_card.dart';

// État local
final imageProvider = StateProvider<File?>((ref) => null);
final analysisProvider = StateProvider<FoodAnalysis?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorProvider = StateProvider<String?>((ref) => null);

class MealCaptureScreen extends ConsumerWidget {
  const MealCaptureScreen({super.key});

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      ref.read(imageProvider.notifier).state = File(pickedFile.path);
      ref.read(analysisProvider.notifier).state = null;
      ref.read(errorProvider.notifier).state = null;
    }
  }

  Future<void> _analyzeImage(WidgetRef ref, BuildContext context) async {
    final imageFile = ref.read(imageProvider);
    if (imageFile == null) return;

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;

    try {
      final visionService = ref.read(visionServiceProvider);
      final analysis = await visionService.analyzeFood(imageFile);
      ref.read(analysisProvider.notifier).state = analysis;
    } catch (e) {
      ref.read(errorProvider.notifier).state = "Erreur lors de l'analyse. Vérifiez votre connexion.";
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(imageProvider);
    final analysis = ref.watch(analysisProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Camera feel
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera/Image Area
            Positioned.fill(
              child: image != null
                  ? Image.file(image, fit: BoxFit.cover)
                  : GestureDetector(
                      onTap: () => _pickImage(ref, ImageSource.camera),
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Prendre en photo mon repas",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "L'IA analysera les glucides pour vous",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // 2. Loading Overlay
            if (image != null && isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),

            // 3. Top Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                       ref.read(imageProvider.notifier).state = null;
                       ref.read(analysisProvider.notifier).state = null;
                       Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Meal Vision",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),

            // 4. Controls / Results Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(error, style: const TextStyle(color: AppColors.error)),
                      ),
                      
                    if (image == null) ...[
                      // Initial State: Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              label: "Galerie",
                              icon: Icons.photo_library,
                              onTap: () => _pickImage(ref, ImageSource.gallery),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              label: "Caméra",
                              icon: Icons.camera_alt,
                              onTap: () => _pickImage(ref, ImageSource.camera),
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                    ] else if (analysis == null && !isLoading) ...[
                      // Image Selected: Analyze Button
                      _buildActionButton(
                        context,
                        label: "Analyser le repas",
                        icon: Icons.auto_awesome,
                        onTap: () => _analyzeImage(ref, context),
                        isPrimary: true,
                        isFullWidth: true,
                      ),
                       const SizedBox(height: 16),
                       TextButton(
                         onPressed: () => ref.read(imageProvider.notifier).state = null,
                         child: const Text("Changer la photo"),
                       )
                    ] else if (analysis != null) ...[
                      // Result State: Coach Bubble & Stats
                      _buildCoachBubble(context, analysis),
                      const SizedBox(height: 20),
                      DiasideCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNutrientInfo("Glucides", "${analysis.carbs}g"),
                            _buildNutrientInfo("Calories", "${analysis.calories}"),
                            _buildNutrientInfo("Confiance", "92%"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        context,
                        label: "Terminer",
                        icon: Icons.check,
                        onTap: () {
                          ref.read(imageProvider.notifier).state = null;
                          ref.read(analysisProvider.notifier).state = null;
                          Navigator.of(context).pop();
                        },
                        isPrimary: true,
                        isFullWidth: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          elevation: 0,
          side: isPrimary ? null : BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPrimary ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachBubble(BuildContext context, FoodAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COACH",
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "I see ${analysis.description}. With ${analysis.carbs}g of carbs and your current glucose (115), a 10 min walk after eating would be perfect!",
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
