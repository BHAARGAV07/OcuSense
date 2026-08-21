class HabitLog {
  final int? id;
  final String patientId;
  final List<String> habits;
  final DateTime timestamp;

  HabitLog({
    this.id,
    required this.patientId,
    required this.habits,
    required this.timestamp,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'],
      patientId: json['patient_id'] ?? '',
      habits: json['habits'] != null ? List<String>.from(json['habits']) : [],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habits': habits,
    };
  }
}
