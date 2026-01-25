import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_models.dart';
import '../providers/coach_provider.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Data
  int _age = 35;
  double _weight = 75;
  double _height = 175;
  String _diabetesType = "Type 1";
  double _hba1c = 7.0;
  int _fastingGlucose = 120;
  double? _ferritin;
  bool _bloodEvent = false;
  String _activityLevel = "moderate";
  String _dietType = "Balanced";
  bool _isSmoker = false;
  bool _isAthlete = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final snapshot = UserHealthSnapshot(
        age: _age,
        weight: _weight,
        height: _height,
        diabetesType: _diabetesType,
        labData: LabData(
          hba1c: _hba1c,
          fastingGlucose: _fastingGlucose,
          ferritin: _ferritin,
          bloodEvent: _bloodEvent,
        ),
        lifestyle: LifestyleProfile(
          activityLevel: _activityLevel,
          dietType: _dietType,
          isSmoker: _isSmoker,
          isAthlete: _isAthlete,
        ),
      );
      
      ref.read(coachProvider.notifier).getAdvice(snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Coach IA (Gemini 3.0)"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text("Profil Biologique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                    initialValue: _age.toString(),
                    onSaved: (v) => _age = int.tryParse(v ?? "") ?? _age,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: "Poids (kg)"),
                          keyboardType: TextInputType.number,
                          initialValue: _weight.toString(),
                          onSaved: (v) => _weight = double.tryParse(v ?? "") ?? _weight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: "Taille (cm)"),
                          keyboardType: TextInputType.number,
                          initialValue: _height.toString(),
                          onSaved: (v) => _height = double.tryParse(v ?? "") ?? _height,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Type de Diabète"),
                    value: _diabetesType,
                    items: ["Type 1", "Type 2", "Gestational"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _diabetesType = v!),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text("Données Labo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "HbA1c (%)"),
                    keyboardType: TextInputType.number,
                    initialValue: _hba1c.toString(),
                    onSaved: (v) => _hba1c = double.tryParse(v ?? "") ?? _hba1c,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Glycémie à jeun (mg/dL)"),
                    keyboardType: TextInputType.number,
                    initialValue: _fastingGlucose.toString(),
                    onSaved: (v) => _fastingGlucose = int.tryParse(v ?? "") ?? _fastingGlucose,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Ferritine (ng/mL) - Optionnel"),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _ferritin = v != null && v.isNotEmpty ? double.tryParse(v) : null,
                  ),
                  SwitchListTile(
                    title: const Text("Perte de sang récente / Don"),
                    value: _bloodEvent,
                    onChanged: (v) => setState(() => _bloodEvent = v),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text("Mode de Vie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Activité"),
                    value: _activityLevel,
                    items: ["sedentary", "moderate", "active"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _activityLevel = v!),
                  ),
                  SwitchListTile(
                    title: const Text("Athlète de haut niveau"),
                    value: _isAthlete,
                    onChanged: (v) => setState(() => _isAthlete = v),
                  ),
                  SwitchListTile(
                    title: const Text("Fumeur"),
                    value: _isSmoker,
                    onChanged: (v) => setState(() => _isSmoker = v),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("OBTENIR CONSEIL COACH"),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.shade100,
                child: Text("Erreur: ${state.error}", style: const TextStyle(color: Colors.red)),
              ),
              
            if (state.data != null)
              Card(
                elevation: 4,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💡 Conseil du Coach :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(state.data!.advice, style: const TextStyle(fontSize: 16)),
                      const Divider(),
                      const Text("🔍 Analyse de Stabilité :", style: TextStyle(fontWeight: FontWeight.bold)),
                      if (state.data!.debugResults['gap_analysis'] != null)
                        Text(state.data!.debugResults['gap_analysis']),
                      Text("HbA1c Labo: ${state.data!.debugResults['hba1c_adjusted']}% (Ajusté)"),
                      Text("Est. CGM: ${state.data!.debugResults['hba1c_estimated_from_cgm']}%"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
