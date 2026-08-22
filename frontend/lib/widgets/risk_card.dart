import 'package:flutter/material.dart';
import '../models/risk.dart';
import '../models/prediction.dart';
import '../theme/app_colors.dart';
import '../screens/prediction/prediction_result_screen.dart';

class RiskCard extends StatelessWidget {
  final RiskAnalysis? riskAnalysis;
  final MLPredictionResult? mlPrediction;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCheckEyes;

  const RiskCard({
    super.key,
    this.riskAnalysis,
    this.mlPrediction,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onCheckEyes,
  });

  Color _getRiskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
      case 'VERY HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      case 'LOW':
      default:
        return AppColors.riskLow;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
      case 'VERY HIGH':
        return Icons.warning_amber_rounded;
      case 'MODERATE':
        return Icons.info_outline_rounded;
      case 'LOW':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.riskHigh),
            const SizedBox(height: 12),
            Text(errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    final level = mlPrediction?.riskLevel ?? riskAnalysis?.riskLevel ?? 'LOW';
    final color = _getRiskColor(level);
    final scorePct = mlPrediction != null
        ? mlPrediction!.riskScorePercentage
        : (riskAnalysis?.riskScore ?? 0);
    final modelVer = mlPrediction?.modelVersion ?? riskAnalysis?.modelVersion ?? 'model unavailable';
    final engine = mlPrediction != null ? 'ml' : (riskAnalysis?.predictionEngine ?? 'unavailable');
    final pollenAvailable = riskAnalysis?.dataAvailability['pollen'] == true;
    final pollenLabel = pollenAvailable
        ? (riskAnalysis?.environment['pollen']?.toString() ?? 'Available')
        : 'Pollen data unavailable';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engine == 'ml' ? 'ML FLARE-RISK ESTIMATE' : 'RISK DATA STATUS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modelVer,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getRiskIcon(level), size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      '$level RISK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$scorePct%',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Probability',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            engine == 'ml'
                ? 'Personalized prototype estimate from available patient, symptom, history, and live environmental signals. $pollenLabel.'
                : 'Prediction engine unavailable. Showing environmental observations where available. $pollenLabel.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),

          // Actions
          Row(
            children: [
              if (mlPrediction != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PredictionResultScreen(result: mlPrediction!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('View Full Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              if (onCheckEyes != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCheckEyes,
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text('Check Eyes Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
