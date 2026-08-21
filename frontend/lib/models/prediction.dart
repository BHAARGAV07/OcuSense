class PredictionContributingFactor {
  final String factorKey;
  final String displayName;
  final double impact;
  final String direction;
  final String reason;
  final String? rawValue;

  PredictionContributingFactor({
    required this.factorKey,
    required this.displayName,
    required this.impact,
    this.direction = 'increases_risk',
    required this.reason,
    this.rawValue,
  });

  factory PredictionContributingFactor.fromJson(Map<String, dynamic> json) {
    return PredictionContributingFactor(
      factorKey: json['factor_key'] ?? '',
      displayName: json['display_name'] ?? 'Unknown Factor',
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] ?? 'increases_risk',
      reason: json['reason'] ?? '',
      rawValue: json['raw_value']?.toString(),
    );
  }
}

class LiteratureReferenceItem {
  final double current;
  final double reference;
  final String unit;
  final bool elevated;

  LiteratureReferenceItem({
    required this.current,
    required this.reference,
    required this.unit,
    required this.elevated,
  });

  factory LiteratureReferenceItem.fromJson(Map<String, dynamic> json) {
    return LiteratureReferenceItem(
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      reference: (json['reference'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      elevated: json['elevated'] ?? false,
    );
  }
}

class MLPredictionResult {
  final String? predictionId;
  final String engine;
  final double riskProbability;
  final int riskScorePercentage;
  final String riskLevel; // LOW, MODERATE, HIGH
  final String predictionWindow;
  final String modelVersion;
  final double confidence;
  final String predictionMode;
  final List<PredictionContributingFactor> topContributingFeatures;
  final Map<String, LiteratureReferenceItem>? literatureReferences;
  final List<String> preventiveGuidance;
  final String disclaimer;

  MLPredictionResult({
    this.predictionId,
    required this.engine,
    required this.riskProbability,
    required this.riskScorePercentage,
    required this.riskLevel,
    required this.predictionWindow,
    required this.modelVersion,
    required this.confidence,
    required this.predictionMode,
    required this.topContributingFeatures,
    this.literatureReferences,
    required this.preventiveGuidance,
    required this.disclaimer,
  });

  factory MLPredictionResult.fromJson(Map<String, dynamic> json) {
    var factors = <PredictionContributingFactor>[];
    if (json['top_contributing_features'] != null) {
      factors = (json['top_contributing_features'] as List)
          .map((item) => PredictionContributingFactor.fromJson(item))
          .toList();
    }

    Map<String, LiteratureReferenceItem>? refs;
    if (json['literature_references'] != null && json['literature_references'] is Map) {
      refs = {};
      final map = json['literature_references'] as Map<String, dynamic>;
      map.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          refs![k] = LiteratureReferenceItem.fromJson(v);
        }
      });
    }

    var guidance = <String>[];
    if (json['preventive_guidance'] != null) {
      guidance = List<String>.from(json['preventive_guidance']);
    }

    return MLPredictionResult(
      predictionId: json['prediction_id'],
      engine: json['engine'] ?? 'ml',
      riskProbability: (json['risk_probability'] as num?)?.toDouble() ?? 0.0,
      riskScorePercentage: (json['risk_score_percentage'] as num?)?.toInt() ?? 0,
      riskLevel: (json['risk_level'] ?? 'LOW').toString().toUpperCase(),
      predictionWindow: json['prediction_window'] ?? '24–72 hours',
      modelVersion: json['model_version'] ?? 'ocular-risk-v0.1-prototype',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      predictionMode: json['prediction_mode'] ?? 'prototype_multivariable_ml',
      topContributingFeatures: factors,
      literatureReferences: refs,
      preventiveGuidance: guidance,
      disclaimer: json['disclaimer'] ?? 'Prototype AI risk estimate; not a diagnosis.',
    );
  }
}

class PredictionComparisonResult {
  final MLPredictionResult mlResult;
  final MLPredictionResult ruleResult;
  final String comparisonNote;

  PredictionComparisonResult({
    required this.mlResult,
    required this.ruleResult,
    required this.comparisonNote,
  });

  factory PredictionComparisonResult.fromJson(Map<String, dynamic> json) {
    return PredictionComparisonResult(
      mlResult: MLPredictionResult.fromJson(json['ml_result']),
      ruleResult: MLPredictionResult.fromJson(json['rule_result']),
      comparisonNote: json['comparison_note'] ?? '',
    );
  }
}
