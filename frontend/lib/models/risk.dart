class ContributingFactor {
  final String factor;
  final int impact;
  final String reason;
  final String confidence;

  ContributingFactor({
    required this.factor,
    required this.impact,
    required this.reason,
    required this.confidence,
  });

  factory ContributingFactor.fromJson(Map<String, dynamic> json) {
    return ContributingFactor(
      factor: json['factor'] ?? 'Unknown',
      impact: (json['impact'] as num?)?.toInt() ?? 0,
      reason: json['reason'] ?? '',
      confidence: json['confidence'] ?? 'moderate',
    );
  }
}

class RiskAnalysis {
  final int riskScore;
  final String riskLevel; // LOW, MODERATE, HIGH
  final List<ContributingFactor> contributingFactors;
  final int observationCount;
  final bool insufficientData;

  RiskAnalysis({
    required this.riskScore,
    required this.riskLevel,
    required this.contributingFactors,
    required this.observationCount,
    required this.insufficientData,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    var factorsList = <ContributingFactor>[];
    if (json['contributing_factors'] != null) {
      factorsList = (json['contributing_factors'] as List)
          .map((item) => ContributingFactor.fromJson(item))
          .toList();
    }
    return RiskAnalysis(
      riskScore: json['risk_score'] ?? 0,
      riskLevel: (json['risk_level'] ?? 'LOW').toString().toUpperCase(),
      contributingFactors: factorsList,
      observationCount: json['observation_count'] ?? 0,
      insufficientData: json['insufficient_data'] ?? false,
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
