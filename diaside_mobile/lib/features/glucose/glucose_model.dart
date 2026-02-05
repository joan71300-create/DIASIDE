class GlucoseEntry {
  final double value; // en mg/dL
  final DateTime timestamp;
  final String? note;
  final String? analysis;

  GlucoseEntry({
    required this.value,
    required this.timestamp,
    this.note,
    this.analysis,
  });

  GlucoseEntry copyWith({
    double? value,
    DateTime? timestamp,
    String? note,
    String? analysis,
  }) {
    return GlucoseEntry(
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      analysis: analysis ?? this.analysis,
    );
  }

  factory GlucoseEntry.fromJson(Map<String, dynamic> json) {
    return GlucoseEntry(
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
      // analysis n'est pas toujours renvoyé par l'API history, on gère
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'analysis': analysis,
  };
}
