import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart'; // Added
import 'dart:convert'; // Added for Base64
// Added
// Added
import '../models/coach_models.dart';
import '../providers/coach_provider.dart';
import '../services/coach_service.dart';
import '../../../core/theme/app_colors.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedImageBase64; // Store selected image temporarily
  
  // Default health data (can be edited in settings)
  UserHealthSnapshot _snapshot = UserHealthSnapshot(
    age: 35, weight: 75, height: 175, diabetesType: "Type 1",
    labData: LabData(hba1c: 7.0, fastingGlucose: 120),
    lifestyle: LifestyleProfile(
      activityLevel: "moderate", 
      dietType: "Balanced", 
      isSmoker: false,
      gender: "Male",
      dailyStepGoal: 10000
    ),
  );

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _selectedImageBase64 = base64String;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image sélectionnée ! Écrivez votre question.")));
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _selectedImageBase64 == null) return;
    
    ref.read(coachProvider.notifier).sendMessage(
      _messageController.text, 
      _snapshot,
      imageBase64: _selectedImageBase64
    );
    
    _messageController.clear();
    setState(() {
      _selectedImageBase64 = null; // Reset image after send
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Quick Actions Logic ---
  Future<void> _logActivity() async {
    final stepsController = TextEditingController();
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("🏃‍♂️ Ajouter Activité"),
        content: TextField(
          controller: stepsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Nombre de pas", suffixText: "pas"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(stepsController.text);
              if (steps != null) {
                try {
                  await coachService.logActivity(DailyStats(
                    date: DateTime.now(), 
                    steps: steps, 
                    caloriesBurned: steps * 0.04, 
                    distanceKm: steps * 0.0007
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activité enregistrée ! Le coach est au courant.")));
                  // Trigger coach update?
                  ref.read(coachProvider.notifier).sendMessage("Je viens de faire $steps pas. Qu'en penses-tu ?", _snapshot);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            }, 
            child: const Text("Enregistrer")
          )
        ],
      )
    );
  }

  Future<void> _logMeal() async {
    final nameController = TextEditingController();
    final carbsController = TextEditingController();
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("🥗 Ajouter Repas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Description du repas")),
            TextField(controller: carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Glucides (estimés)", suffixText: "g")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await coachService.logMeal(Meal(
                    timestamp: DateTime.now(),
                    name: nameController.text,
                    carbs: double.tryParse(carbsController.text)
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Repas enregistré !")));
                   ref.read(coachProvider.notifier).sendMessage("Je viens de manger : ${nameController.text}. Analyse ?", _snapshot);
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            }, 
            child: const Text("Enregistrer")
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("COACH DIASIDE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Log Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.directions_walk, size: 16),
                  label: const Text("Activité"),
                  onPressed: _logActivity,
                  backgroundColor: Colors.white,
                  elevation: 1,
                ),
                ActionChip(
                  avatar: const Icon(Icons.restaurant, size: 16),
                  label: const Text("Repas"),
                  onPressed: _logMeal,
                  backgroundColor: Colors.white,
                  elevation: 1,
                ),
                ActionChip(
                  avatar: const Icon(Icons.monitor_weight, size: 16),
                  label: const Text("Poids"),
                  onPressed: () { /* TODO */ },
                  backgroundColor: Colors.white,
                  elevation: 1,
                ),
              ],
            ),
          ),
          
          // Chat Area
          Expanded(
            child: state.history.isEmpty && state.data == null && !state.isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: state.history.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.history.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = state.history[index];
                      return _buildChatBubble(msg);
                    },
                  ),
          ),

          // Action Area (if coach replied)
          if (state.data != null && state.data!.actions.isNotEmpty)
            _buildActionShortcuts(state.data!.actions),

          // Input Area
          _buildInputArea(state.isLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "Bonjour ! Je suis votre Coach Santé.",
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "On analyse votre journée ? (Pas, Repas, Glycémie)",
            style: GoogleFonts.poppins(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: isUser 
          ? Text(msg.content, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15))
          : MarkdownBody(
              data: msg.content,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 15, height: 1.5),
              ),
            ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withOpacity(0.5))),
            const SizedBox(width: 8),
            Text("Analyse en cours...", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionShortcuts(List<CoachAction> actions) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(action.label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.primaryLight,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _messageController.text = "Comment faire pour : ${action.label} ?";
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview Image
          if (_selectedImageBase64 != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_selectedImageBase64!)),
                        fit: BoxFit.cover
                      )
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Image jointe", style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _selectedImageBase64 = null),
                  )
                ],
              ),
            ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                onPressed: isLoading ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Écrivez ici...",
                    hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: isLoading ? AppColors.textTertiary : AppColors.primary),
                onPressed: isLoading ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    // Basic implementation for settings
    // In a real app, bind this to state
    String activity = _snapshot.lifestyle.activityLevel;
    String gender = _snapshot.lifestyle.gender;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text("Profil Santé", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  items: ["Male", "Female", "Other"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => gender = v!),
                  decoration: const InputDecoration(labelText: "Genre"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  items: ["sedentary", "moderate", "active"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => activity = v!),
                  decoration: const InputDecoration(labelText: "Niveau d'activité"),
                ),
                
                const Spacer(),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () {
                    // Update Local State (In real app, update DB via API)
                    this.setState(() {
                      _snapshot = UserHealthSnapshot(
                        age: _snapshot.age,
                        weight: _snapshot.weight,
                        height: _snapshot.height,
                        diabetesType: _snapshot.diabetesType,
                        labData: _snapshot.labData,
                        lifestyle: LifestyleProfile(
                          activityLevel: activity,
                          dietType: _snapshot.lifestyle.dietType,
                          isSmoker: _snapshot.lifestyle.isSmoker,
                          gender: gender,
                          dailyStepGoal: _snapshot.lifestyle.dailyStepGoal
                        )
                      );
                    });
                    Navigator.pop(context);
                  }, 
                  child: const Text("Enregistrer")
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
