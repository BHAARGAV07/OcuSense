class ContributingFactor {
  final String factor;
  final double impact;
  final String reason;
  final String? confidence;
  final String? rawValue;

  ContributingFactor({
    required this.factor,
    required this.impact,
    required this.reason,
    this.confidence,
    this.rawValue,
  });

  factory ContributingFactor.fromJson(Map<String, dynamic> json) {
    return ContributingFactor(
      factor: json['factor'] ?? json['display_name'] ?? json['factor_key'] ?? 'Unknown',
      impact: (json['impact'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] ?? '',
      confidence: json['confidence'],
      rawValue: json['raw_value']?.toString(),
    );
  }
}

class RiskAnalysis {
  final int riskScore;
  final double? riskProbability;
  final String riskLevel; // LOW, MODERATE, HIGH
  final String predictionEngine;
  final String? modelVersion;
  final List<ContributingFactor> contributingFactors;
  final int observationCount;
  final bool insufficientData;
  final Map<String, dynamic> environment;
  final Map<String, dynamic> dataAvailability;
  final Map<String, dynamic> dataErrors;
  final String disclaimer;

  RiskAnalysis({
    required this.riskScore,
    this.riskProbability,
    required this.riskLevel,
    required this.predictionEngine,
    this.modelVersion,
    required this.contributingFactors,
    required this.observationCount,
    required this.insufficientData,
    required this.environment,
    required this.dataAvailability,
    required this.dataErrors,
    required this.disclaimer,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    var factorsList = <ContributingFactor>[];
    final rawFactors = json['contributing_factors'] ?? json['top_contributing_features'];
    if (rawFactors is List) {
      factorsList = rawFactors
          .whereType<Map>()
          .map((item) => ContributingFactor.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return RiskAnalysis(
      riskScore: (json['risk_score'] as num?)?.toInt() ??
          (json['risk_score_percentage'] as num?)?.toInt() ??
          0,
      riskProbability: (json['risk_probability'] as num?)?.toDouble(),
      riskLevel: (json['risk_level'] ?? 'LOW').toString().toUpperCase(),
      predictionEngine: (json['prediction_engine'] ?? json['engine'] ?? 'unavailable').toString(),
      modelVersion: json['model_version']?.toString(),
      contributingFactors: factorsList,
      observationCount: json['observation_count'] ?? 0,
      insufficientData: json['insufficient_data'] ?? false,
      environment: (json['environment'] as Map?)?.cast<String, dynamic>() ?? {},
      dataAvailability: (json['data_availability'] as Map?)?.cast<String, dynamic>() ?? {},
      dataErrors: (json['data_errors'] as Map?)?.cast<String, dynamic>() ?? {},
      disclaimer: json['disclaimer']?.toString() ?? '',
    );
  }
}

class RiskHistoryItem {
  final String date;
  final int riskScore;
  final String riskLevel;
  final String primaryFactor;

  RiskHistoryItem({
    required this.date,
    required this.riskScore,
    required this.riskLevel,
    required this.primaryFactor,
  });

  factory RiskHistoryItem.fromJson(Map<String, dynamic> json) {
    return RiskHistoryItem(
      date: json['date'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      riskLevel: (json['risk_level'] ?? 'LOW').toString().toUpperCase(),
      primaryFactor: json['primary_factor'] ?? 'General',
    );
  }
}
