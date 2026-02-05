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
  final String gender;
  final int dailyStepGoal;

  LifestyleProfile({
    required this.activityLevel,
    required this.dietType,
    required this.isSmoker,
    this.isAthlete = false,
    this.gender = "Male",
    this.dailyStepGoal = 10000,
  });

  Map<String, dynamic> toJson() => {
    'activity_level': activityLevel,
    'diet_type': dietType,
    'is_smoker': isSmoker,
    'is_athlete': isAthlete,
    'gender': gender,
    'daily_step_goal': dailyStepGoal,
  };
}

class DailyStats {
  final DateTime date;
  final int steps;
  final double caloriesBurned;
  final double distanceKm;

  DailyStats({
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.distanceKm,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'steps': steps,
    'calories_burned': caloriesBurned,
    'distance_km': distanceKm,
  };
}

class Meal {
  final DateTime timestamp;
  final String name;
  final double? calories;
  final double? carbs;

  Meal({
    required this.timestamp,
    required this.name,
    this.calories,
    this.carbs,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'name': name,
    'calories': calories,
    'carbs': carbs,
  };
}

class UserHealthSnapshot {
  final int age;
  final double weight;
  final double height;
  final String diabetesType;
  final LabData labData;
  final LifestyleProfile lifestyle;
  final List<DailyStats> recentActivity;
  final List<Meal> recentMeals;

  UserHealthSnapshot({
    required this.age,
    required this.weight,
    required this.height,
    required this.diabetesType,
    required this.labData,
    required this.lifestyle,
    this.recentActivity = const [],
    this.recentMeals = const [],
  });

  Map<String, dynamic> toJson() => {
    'age': age,
    'weight': weight,
    'height': height,
    'diabetes_type': diabetesType,
    'lab_data': labData.toJson(),
    'lifestyle': lifestyle.toJson(),
    'recent_activity': recentActivity.map((e) => e.toJson()).toList(),
    'recent_meals': recentMeals.map((e) => e.toJson()).toList(),
  };
}

class CoachAction {
  final String label;
  final String type;

  CoachAction({required this.label, required this.type});

  factory CoachAction.fromJson(Map<String, dynamic> json) {
    return CoachAction(
      label: json['label'],
      type: json['type'],
    );
  }
}


class CoachResponse {
  final String advice;
  final List<CoachAction> actions;
  final Map<String, dynamic> debugResults;

  CoachResponse({required this.advice, required this.actions, required this.debugResults});

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    var actionsList = <CoachAction>[];
    if (json['actions'] != null) {
      actionsList = (json['actions'] as List)
          .map((e) => CoachAction.fromJson(e))
          .toList();
    }

    return CoachResponse(
      advice: json['advice'],
      actions: actionsList,
      debugResults: json['debug_results'] ?? {},
    );
  }
}

class ChatMessage {
  final String role; // "user" or "model"
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

class ChatRequest {
  final UserHealthSnapshot snapshot;
  final List<ChatMessage> history;
  final String? userMessage;
  final String? imageBase64;

  ChatRequest({
    required this.snapshot,
    this.history = const [],
    this.userMessage,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
    'snapshot': snapshot.toJson(),
    'history': history.map((e) => e.toJson()).toList(),
    'user_message': userMessage,
    'image_base64': imageBase64,
  };
}
