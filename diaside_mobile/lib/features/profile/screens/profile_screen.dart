import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_card.dart';
import '../../../features/auth/services/auth_service.dart';
import 'edit_profile_screen.dart';
import '../models/health_profile.dart';
import '../health_profile_provider.dart';
import '../../glucose/glucose_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(healthProfileProvider);
    final glucoseEntries = ref.watch(glucoseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MON PROFIL', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER AVEC AVATAR ===
                  _buildHeader(context, profile),
                  
                  const SizedBox(height: 24),

                  // === DIAGNOSTIC ===
                  _buildSectionTitle("DIAGNOSTIC"),
                  DiasideCard(
                    child: Column(
                      children: [
                        _buildInfoRow("Type", profile.diabetesType, Icons.bloodtype),
                        const Divider(height: 1),
                        _buildInfoRow("Depuis", "${profile.diabetesYears ?? 'N/A'} ans", Icons.calendar_today),
                        if (profile.targetHbA1c != null) ...[
                          const Divider(height: 1),
                          _buildInfoRow("Objectif HbA1c", "${profile.targetHbA1c}%", Icons.flag),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === CORPS ===
                  _buildSectionTitle("CORPS"),
                  DiasideCard(
                    child: Column(
                      children: [
                        _buildInfoRow("Poids", "${profile.weight ?? 'N/A'} kg", Icons.monitor_weight),
                        const Divider(height: 1),
                        _buildInfoRow("Taille", "${profile.height ?? 'N/A'} cm", Icons.height),
                        const Divider(height: 1),
                        _buildInfoRow("IMC", "${profile.imc?.toStringAsFixed(1) ?? 'N/A'} - ${profile.imcCategory}", Icons.analytics),
                        const Divider(height: 1),
                        _buildInfoRow("Forme", DiabetesComplications.getActivityLabel(profile.activityLevel), Icons.directions_run),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === TRAITEMENTS ===
                  if (profile.treatments.isNotEmpty) ...[
                    _buildSectionTitle("TRAITEMENTS"),
                    DiasideCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.treatments.map((t) => Chip(
                          label: Text(t, style: GoogleFonts.poppins(fontSize: 12)),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === COMPLICATIONS ===
                  if (profile.complications.isNotEmpty) ...[
                    _buildSectionTitle("COMPLICATIONS"),
                    DiasideCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.complications.map((c) => Chip(
                          label: Text(c, style: GoogleFonts.poppins(fontSize: 12)),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          avatar: const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === ÉTAT ACTUEL / BLESSURES ===
                  if (profile.injuries.isNotEmpty || profile.currentSymptoms.isNotEmpty) ...[
                    _buildSectionTitle("ÉTAT ACTUEL"),
                    DiasideCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.injuries.isNotEmpty) ...[
                            Text("Blessures/Douleurs", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.injuries.map((i) => Chip(
                                label: Text(i, style: GoogleFonts.poppins(fontSize: 12)),
                                backgroundColor: Colors.red.withOpacity(0.1),
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (profile.currentSymptoms.isNotEmpty) ...[
                            Text("Symptômes", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.currentSymptoms.map((s) => Chip(
                                label: Text(s, style: GoogleFonts.poppins(fontSize: 12)),
                                backgroundColor: Colors.amber.withOpacity(0.1),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === STATS GLYCÉMIQUES ===
                  if (glucoseEntries.isNotEmpty) ...[
                    _buildSectionTitle("STATISTIQUES"),
                    DiasideCard(
                      child: Column(
                        children: [
                          _buildInfoRow("Mesures", "${glucoseEntries.length}", Icons.bloodtype_outlined),
                          const Divider(height: 1),
                          _buildInfoRow("Dernière", _formatLastMeasure(glucoseEntries), Icons.access_time),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === MENU SETTINGS ===
                  _buildSectionTitle("PARAMÈTRES"),
                  DiasideCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context,
                          Icons.person_outline,
                          "Modifier mon profil",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        ),
                        const Divider(height: 1),
                        _buildMenuItem(
                          context,
                          Icons.tune,
                          "Calibration HbA1c",
                          () => _showCalibrationDialog(context, ref),
                        ),
                        const Divider(height: 1),
                        _buildMenuItem(
                          context,
                          Icons.notifications_none,
                          "Notifications",
                          () {},
                        ),
                        const Divider(height: 1),
                        _buildMenuItem(
                          context,
                          Icons.help_outline,
                          "Aide & Support",
                          () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === BOUTON LOGOUT ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      label: Text("Déconnexion", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, HealthProfile profile) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              profile.name?.substring(0, 1).toUpperCase() ?? "U",
              style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name ?? "Utilisateur",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? "email@exemple.com",
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  String _formatLastMeasure(List<dynamic> entries) {
    if (entries.isEmpty) return "N/A";
    final last = entries.last;
    final diff = DateTime.now().difference(last.timestamp);
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "Il y a ${diff.inDays} jours";
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
            const Text("Entrez votre dernière HbA1c sanguine pour ajuster l'estimation."),
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
                ref.read(hba1cOffsetProvider.notifier).state = labVal - 8.2;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calibration enregistrée !")));
              }
            },
            child: const Text("Valider")
          )
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Déconnexion", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }
}
