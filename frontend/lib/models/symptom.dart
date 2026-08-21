class SymptomLog {
  final int? id;
  final String patientId;
  final List<String> symptoms;
  final String severity;
  final int severityScore;
  final bool recentSymptomsIncreased;
  final DateTime timestamp;

  SymptomLog({
    this.id,
    required this.patientId,
    required this.symptoms,
    required this.severity,
    required this.severityScore,
    required this.recentSymptomsIncreased,
    required this.timestamp,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'],
      patientId: json['patient_id'] ?? '',
      symptoms: json['symptoms'] != null ? List<String>.from(json['symptoms']) : [],
      severity: json['severity'] ?? 'LOW',
      severityScore: json['severity_score'] ?? 5,
      recentSymptomsIncreased: json['recent_symptoms_increased'] ?? false,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms,
      'severity': severity,
      'severity_score': severityScore,
      'recent_symptoms_increased': recentSymptomsIncreased,
    };
  }
}
