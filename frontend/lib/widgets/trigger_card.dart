import 'package:flutter/material.dart';
import '../models/trigger.dart';
import '../theme/app_colors.dart';

class TriggerCard extends StatelessWidget {
  final TriggerAssociation trigger;

  const TriggerCard({super.key, required this.trigger});

  String _getFactorEmoji(String factor) {
    switch (factor.toLowerCase()) {
      case 'dust':
        return '🌫️';
      case 'pollen':
        return '🌱';
      case 'humidity':
        return '💧';
      case 'eye_rubbing':
        return '👁️';
      default:
        return '⚠️';
    }
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
      case 'strong':
        return AppColors.riskHigh;
      case 'moderate':
        return AppColors.riskModerate;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _getFactorEmoji(trigger.factor);
    final confColor = _getConfidenceColor(trigger.confidence);
    final progress = (trigger.associationScore / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trigger.factor.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Lift Ratio: ${trigger.lift.toStringAsFixed(1)}x  •  ${trigger.confidence.toUpperCase()} Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: confColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${trigger.associationScore.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(confColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${trigger.observationCount} days of localized observation.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
