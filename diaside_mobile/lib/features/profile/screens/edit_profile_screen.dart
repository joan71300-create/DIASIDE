import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_button.dart';
import '../models/health_profile.dart';
import '../health_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _diabetesType = "Type 1";
  String _gender = "Male";
  String _activityLevel = "moderate";
  String? _insulinType;
  List<String> _selectedTreatments = [];
  List<String> _selectedComplications = [];
  List<String> _selectedInjuries = [];
  List<String> _selectedSymptoms = [];
  double? _targetHbA1c;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final profile = ref.read(healthProfileProvider);
    if (profile != null) {
      setState(() {
        _nameController.text = profile.name ?? "";
        _weightController.text = profile.weight?.toString() ?? "";
        _heightController.text = profile.height?.toString() ?? "";
        _notesController.text = profile.notes ?? "";
        _diabetesType = profile.diabetesType;
        _gender = profile.gender ?? "Male";
        _activityLevel = profile.activityLevel;
        _insulinType = profile.insulinType;
        _selectedTreatments = List.from(profile.treatments);
        _selectedComplications = List.from(profile.complications);
        _selectedInjuries = List.from(profile.injuries);
        _selectedSymptoms = List.from(profile.currentSymptoms);
        _targetHbA1c = profile.targetHbA1c;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    final profile = HealthProfile(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
      gender: _gender,
      diabetesType: _diabetesType,
      insulinType: _insulinType,
      treatments: _selectedTreatments,
      targetHbA1c: _targetHbA1c,
      activityLevel: _activityLevel,
      complications: _selectedComplications,
      injuries: _selectedInjuries,
      currentSymptoms: _selectedSymptoms,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await ref.read(healthProfileProvider.notifier).updateProfile(profile);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour !")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de sauvegarde")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Mon Profil Santé", style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === INFORMATIONS DE BASE ===
                  _buildSectionTitle("INFORMATIONS DE BASE"),
                  _buildTextField("Nom / Surnom", _nameController),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown("Genre", _gender, ["Male", "Female", "Other"], (v) => setState(() => _gender = v!))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown("Activité", _activityLevel, DiabetesComplications.activityLevels, (v) => setState(() => _activityLevel = v!))),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // === CORPS ===
                  _buildSectionTitle("CORPS"),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Poids (kg)", _weightController, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField("Taille (cm)", _heightController, isNumber: true)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // === DIABÈTE ===
                  _buildSectionTitle("DIABÈTE"),
                  _buildDropdown("Type de diabète", _diabetesType, ["Type 1", "Type 2", "LADA", "Gestationnel"], (v) => setState(() => _diabetesType = v!)),
                  const SizedBox(height: 16),
                  _buildDropdown("Type d'insuline", _insulinType ?? "Non", ["Non", "Insuline rapide", "Insuline lente", "Insuline mixte", "Pompe"], (v) => setState(() => _insulinType = v == "Non" ? null : v)),
                  const SizedBox(height: 16),
                  _buildTextField("Objectif HbA1c (%)", null, isNumber: true, suffix: "%", onChanged: (v) => _targetHbA1c = double.tryParse(v)),

                  const SizedBox(height: 30),

                  // === TRAITEMENTS ===
                  _buildSectionTitle("TRAITEMENTS"),
                  _buildChipSelector("Traitements", _selectedTreatments, DiabetesComplications.treatments),

                  const SizedBox(height: 30),

                  // === COMPLICATIONS ===
                  _buildSectionTitle("COMPLICATIONS"),
                  _buildChipSelector("Complications", _selectedComplications, DiabetesComplications.common),

                  const SizedBox(height: 30),

                  // === BLESSURES / DOULEURS ===
                  _buildSectionTitle("BLESSURES / DOULEURS"),
                  _buildChipSelector("Blessures", _selectedInjuries, DiabetesComplications.injuries),

                  const SizedBox(height: 30),

                  // === SYMPTÔMES ===
                  _buildSectionTitle("SYMPTÔMES ACTUELS"),
                  _buildChipSelector("Symptômes", _selectedSymptoms, DiabetesComplications.symptoms),

                  const SizedBox(height: 30),

                  // === NOTES ===
                  _buildSectionTitle("NOTES"),
                  _buildTextField("Notes supplémentaires", _notesController, maxLines: 3, hint: "Toutes informations utiles pour votre coach..."),

                  const SizedBox(height: 40),
                  DiasideButton(label: "Enregistrer", onPressed: _save),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller, {bool isNumber = false, int maxLines = 1, String? hint, String? suffix, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelector(String label, List<String> selectedItems, List<String> allItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(item, style: GoogleFonts.poppins(fontSize: 12)),
              selected: isSelected,
              onSelected: (bool sel) {
                setState(() {
                  if (sel) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}
