class OcularAnalysisResult {
  final bool success;
  final bool isAcceptable;
  final double imageQuality;
  final double? rednessScore;
  final double? inflammationScore;
  final double? swellingScore;
  final double? tearFeature;
  final double confidence;
  final String feedback;
  final String? error;
  final int? framesAnalyzed;

  OcularAnalysisResult({
    required this.success,
    required this.isAcceptable,
    required this.imageQuality,
    this.rednessScore,
    this.inflammationScore,
    this.swellingScore,
    this.tearFeature,
    this.confidence = 0.85,
    required this.feedback,
    this.error,
    this.framesAnalyzed,
  });

  factory OcularAnalysisResult.fromJson(Map<String, dynamic> json) {
    return OcularAnalysisResult(
      success: json['success'] ?? false,
      isAcceptable: json['is_acceptable'] ?? false,
      imageQuality: (json['image_quality'] as num?)?.toDouble() ?? 0.0,
      rednessScore: (json['redness_score'] as num?)?.toDouble(),
      inflammationScore: (json['inflammation_score'] as num?)?.toDouble(),
      swellingScore: (json['swelling_score'] as num?)?.toDouble(),
      tearFeature: (json['tear_feature'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      feedback: json['feedback'] ?? '',
      error: json['error'],
      framesAnalyzed: (json['frames_analyzed'] as num?)?.toInt(),
    );
  }
}
