/// Modèle de profil santé pour le coaching diabète
/// Contient toutes les informations de santé importantes pour le Coach AI

class HealthProfile {
  // === INFORMATIONS DE BASE ===
  final String? name;
  final int? age;
  final String? gender;
  final double? weight; // kg
  final double? height; // cm
  
  // === DIABÈTE ===
  final String diabetesType; // Type 1, Type 2, LADA, Gestationnel
  final DateTime? diagnosisDate;
  final String? insulinType; // Rapide, Lente, Mixte, Pompe
  final List<String> treatments; // Insuline, Metformine, Inhibiteurs SGLT2, etc.
  
  // === OBJECTIFS ===
  final double? targetHbA1c;
  final DateTime? targetHbA1cDate;
  final double? targetWeight;
  
  // === ÉTAT DE SANTÉ ACTUEL ===
  final String activityLevel; // sedentary, moderate, active, athlete
  final List<String> currentSymptoms; // Fatigue, soif excessive, vertiges...
  final List<String> complications; // Neuropathie, rétinopathie, néphropathie...
  final List<String> injuries; // Blessures actuelles
  final String? notes;
  
  // === DONNÉES CALCULÉES ===
  double? get imc {
    if (weight == null || height == null || height! <= 0) return null;
    final heightM = height! / 100;
    return weight! / (heightM * heightM);
  }
  
  int? get diabetesYears {
    if (diagnosisDate == null) return null;
    return DateTime.now().difference(diagnosisDate!).inDays ~/ 365;
  }
  
  String get imcCategory {
    final imcValue = imc;
    if (imcValue == null) return "N/A";
    if (imcValue < 18.5) return "Insuffisance pondérale";
    if (imcValue < 25) return "Normal";
    if (imcValue < 30) return "Surpoids";
    return "Obésité";
  }

  HealthProfile({
    this.name,
    this.age,
    this.gender,
    this.weight,
    this.height,
    this.diabetesType = "Type 1",
    this.diagnosisDate,
    this.insulinType,
    this.treatments = const [],
    this.targetHbA1c,
    this.targetHbA1cDate,
    this.targetWeight,
    this.activityLevel = "moderate",
    this.currentSymptoms = const [],
    this.complications = const [],
    this.injuries = const [],
    this.notes,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      diabetesType: json['diabetes_type'] ?? "Type 1",
      diagnosisDate: json['diagnosis_date'] != null 
          ? DateTime.tryParse(json['diagnosis_date']) 
          : null,
      insulinType: json['insulin_type'],
      treatments: json['treatments'] != null 
          ? List<String>.from(json['treatments']) 
          : [],
      targetHbA1c: json['target_hba1c']?.toDouble(),
      targetHbA1cDate: json['target_hba1c_date'] != null 
          ? DateTime.tryParse(json['target_hba1c_date']) 
          : null,
      targetWeight: json['target_weight']?.toDouble(),
      activityLevel: json['activity_level'] ?? "moderate",
      currentSymptoms: json['current_symptoms'] != null 
          ? List<String>.from(json['current_symptoms']) 
          : [],
      complications: json['complications'] != null 
          ? List<String>.from(json['complications']) 
          : [],
      injuries: json['injuries'] != null 
          ? List<String>.from(json['injuries']) 
          : [],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'diabetes_type': diabetesType,
      'diagnosis_date': diagnosisDate?.toIso8601String(),
      'insulin_type': insulinType,
      'treatments': treatments,
      'target_hba1c': targetHbA1c,
      'target_hba1c_date': targetHbA1cDate?.toIso8601String(),
      'target_weight': targetWeight,
      'activity_level': activityLevel,
      'current_symptoms': currentSymptoms,
      'complications': complications,
      'injuries': injuries,
      'notes': notes,
    };
  }

  HealthProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    String? diabetesType,
    DateTime? diagnosisDate,
    String? insulinType,
    List<String>? treatments,
    double? targetHbA1c,
    DateTime? targetHbA1cDate,
    double? targetWeight,
    String? activityLevel,
    List<String>? currentSymptoms,
    List<String>? complications,
    List<String>? injuries,
    String? notes,
  }) {
    return HealthProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      diabetesType: diabetesType ?? this.diabetesType,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      insulinType: insulinType ?? this.insulinType,
      treatments: treatments ?? this.treatments,
      targetHbA1c: targetHbA1c ?? this.targetHbA1c,
      targetHbA1cDate: targetHbA1cDate ?? this.targetHbA1cDate,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      currentSymptoms: currentSymptoms ?? this.currentSymptoms,
      complications: complications ?? this.complications,
      injuries: injuries ?? this.injuries,
      notes: notes ?? this.notes,
    );
  }

  /// Génère un résumé pour le Coach AI
  String toCoachSummary() {
    final buffer = StringBuffer();
    
    buffer.writeln("=== PROFIL SANTÉ ===");
    
    if (age != null) buffer.writeln("Âge: $age ans");
    if (gender != null) buffer.writeln("Genre: $gender");
    if (weight != null) buffer.writeln("Poids: ${weight}kg");
    if (height != null) buffer.writeln("Taille: ${height}cm (IMC: ${imc?.toStringAsFixed(1) ?? 'N/A'} - $imcCategory)");
    
    buffer.writeln("\n=== DIABÈTE ===");
    buffer.writeln("Type: $diabetesType");
    if (diabetesYears != null) buffer.writeln("Diagnostiqué depuis: $diabetesYears ans");
    if (insulinType != null) buffer.writeln("Traitement insuline: $insulinType");
    if (treatments.isNotEmpty) buffer.writeln("Traitements: ${treatments.join(', ')}");
    
    if (targetHbA1c != null) {
      buffer.writeln("\n=== OBJECTIFS ===");
      buffer.writeln("HbA1c cible: ${targetHbA1c}%");
    }
    
    if (complications.isNotEmpty || injuries.isNotEmpty || currentSymptoms.isNotEmpty) {
      buffer.writeln("\n=== ÉTAT ACTUEL ===");
      if (complications.isNotEmpty) buffer.writeln("Complications: ${complications.join(', ')}");
      if (injuries.isNotEmpty) buffer.writeln("Blessures: ${injuries.join(', ')}");
      if (currentSymptoms.isNotEmpty) buffer.writeln("Symptômes: ${currentSymptoms.join(', ')}");
    }
    
    buffer.writeln("\nActivité: $activityLevel");
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln("\nNotes: $notes");
    }
    
    return buffer.toString();
  }
}

/// Liste des complications courantes du diabète
class DiabetesComplications {
  static const List<String> common = [
    "Aucune complication",
    "Neuropathie légère",
    "Neuropathie modérée",
    "Rétinopathie légère",
    "Rétinopathie modérée",
    "Néphropathie",
    "Maladie cardiovasculaire",
    "Hypertension",
    "Dyslipidémie",
    "Pied diabétique",
    "Artérite des membres inférieurs",
  ];
  
  static const List<String> symptoms = [
    "Aucune",
    "Fatigue",
    "Soif excessive",
    "Vision floue",
    "Vertiges",
    "Hypoglycémies nocturnes",
    "Hypoglycémies fréquentes",
    "Hyperglycémies matinales",
    "Douleurs neuropathiques",
    "Gonflement des pieds",
    "Prise de poids récente",
    "Perte de poids récente",
  ];
  
  static const List<String> injuries = [
    "Aucune",
    "Douleur pied gauche",
    "Douleur pied droit",
    "Entorse",
    "Tendinite",
    "Dorsalgie",
    "Céphalées",
    "Douleurs articulaires",
    " cicatrisation lente",
  ];
  
  static const List<String> treatments = [
    "Insuline rapide (Apidra, Humalog, Novorapid)",
    "Insuline lente (Lantus, Toujeo, Levemir)",
    "Insuline mixte",
    "Pompe à insuline",
    "Metformine",
    "Inhibiteurs SGLT2 (Jardiance, Forxiga)",
    "GLP-1 (Ozempic, Trulicity)",
    "Sulfonylurées",
    "Aspirine",
    "Statines",
    "IEC (Lisinopril, Ramipril)",
    "ARB (Losartan, Valsartan)",
  ];
  
  static const List<String> activityLevels = [
    "sedentary",
    "moderate",
    "active",
    "athlete",
  ];
  
  static String getActivityLabel(String level) {
    switch (level) {
      case "sedentary": return "Sédentaire (peu d'activité)";
      case "moderate": return "Modérée (30-60 min/jour)";
      case "active": return "Active (60+ min/jour)";
      case "athlete": return "Athlete (entraînement intensif)";
      default: return level;
    }
  }
}
