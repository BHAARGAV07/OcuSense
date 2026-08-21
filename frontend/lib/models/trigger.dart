class TriggerAssociation {
  final String factor;
  final double associationScore;
  final double lift;
  final String confidence;
  final int observationCount;

  TriggerAssociation({
    required this.factor,
    required this.associationScore,
    required this.lift,
    required this.confidence,
    required this.observationCount,
  });

  factory TriggerAssociation.fromJson(Map<String, dynamic> json) {
    return TriggerAssociation(
      factor: json['factor'] ?? '',
      associationScore: (json['association_score'] as num?)?.toDouble() ?? 0.0,
      lift: (json['lift'] as num?)?.toDouble() ?? 1.0,
      confidence: json['confidence'] ?? 'moderate',
      observationCount: json['observation_count'] ?? 0,
    );
  }
}
