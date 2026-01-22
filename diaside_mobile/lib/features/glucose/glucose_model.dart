class GlucoseEntry {
  final double value; // en $mg/dL$
  final DateTime timestamp;
  final String? note;

  GlucoseEntry({required this.value, required this.timestamp, this.note});
}
