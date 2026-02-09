import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_button.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _limitationsController = TextEditingController();
  String _diabetesType = "Type 1";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await profileService.getProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile['name'] ?? "";
        _ageController.text = profile['age']?.toString() ?? "";
        _weightController.text = profile['weight']?.toString() ?? "";
        _heightController.text = profile['height']?.toString() ?? "";
        _limitationsController.text = profile['physical_limitations'] ?? "";
        _diabetesType = profile['diabetes_type'] ?? "Type 1";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    final data = {
      "name": _nameController.text,
      "age": int.tryParse(_ageController.text) ?? 30,
      "weight": double.tryParse(_weightController.text) ?? 70.0,
      "height": double.tryParse(_heightController.text) ?? 170.0,
      "diabetes_type": _diabetesType,
      "physical_limitations": _limitationsController.text,
      "target_glucose_min": 70, // Default
      "target_glucose_max": 180, // Default
    };

    final success = await profileService.updateProfile(data);
    
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
        title: Text("Profil", style: GoogleFonts.poppins(color: AppColors.textPrimary)),
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
                  Text("Personnalisation", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Ces informations permettent au Coach IA de mieux vous conseiller.", style: TextStyle(color: AppColors.textSecondary)),
                  
                  const SizedBox(height: 30),
                  
                  _buildTextField("Nom / Surnom", _nameController),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Age", _ageController, isNumber: true)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField("Poids (kg)", _weightController, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Taille (cm)", _heightController, isNumber: true),
                  
                  const SizedBox(height: 20),
                  Text("Type de Diabète", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: _diabetesType,
                    isExpanded: true,
                    items: ["Type 1", "Type 2", "Gestational"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _diabetesType = val!),
                  ),

                  const SizedBox(height: 20),
                  _buildTextField("Limitations Physiques", _limitationsController, maxLines: 3, hint: "Ex: Douleur genou, asthme, marche difficile..."),

                  const SizedBox(height: 40),
                  DiasideButton(label: "Enregistrer", onPressed: _save),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
