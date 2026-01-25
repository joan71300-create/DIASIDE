class LabData {
  final double hba1c;
  final int fastingGlucose;
  final double? ferritin;
  final bool bloodEvent;

  LabData({
    required this.hba1c,
    required this.fastingGlucose,
    this.ferritin,
    this.bloodEvent = false,
  });

  Map<String, dynamic> toJson() => {
    'hba1c': hba1c,
    'fasting_glucose': fastingGlucose,
    'ferritin': ferritin,
    'blood_event': bloodEvent,
  };
}

class LifestyleProfile {
  final String activityLevel;
  final String dietType;
  final bool isSmoker;
  final bool isAthlete;

  LifestyleProfile({
    required this.activityLevel,
    required this.dietType,
    required this.isSmoker,
    this.isAthlete = false,
  });

  Map<String, dynamic> toJson() => {
    'activity_level': activityLevel,
    'diet_type': dietType,
    'is_smoker': isSmoker,
    'is_athlete': isAthlete,
  };
}

class UserHealthSnapshot {
  final int age;
  final double weight;
  final double height;
  final String diabetesType;
  final LabData labData;
  final LifestyleProfile lifestyle;

  UserHealthSnapshot({
    required this.age,
    required this.weight,
    required this.height,
    required this.diabetesType,
    required this.labData,
    required this.lifestyle,
  });

  Map<String, dynamic> toJson() => {
    'age': age,
    'weight': weight,
    'height': height,
    'diabetes_type': diabetesType,
    'lab_data': labData.toJson(),
    'lifestyle': lifestyle.toJson(),
  };
}

class CoachResponse {
  final String advice;
  final Map<String, dynamic> debugResults;

  CoachResponse({required this.advice, required this.debugResults});

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    return CoachResponse(
      advice: json['advice'],
      debugResults: json['debug_results'] ?? {},
    );
  }
}
