import 'package:flutter/material.dart';
import '../models/risk.dart';
import '../theme/app_colors.dart';

class RiskCard extends StatelessWidget {
  final RiskAnalysis? riskAnalysis;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const RiskCard({
    super.key,
    this.riskAnalysis,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  Color _getRiskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
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
        padding: const EdgeInsets.all(24),
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

    final risk = riskAnalysis;
    final level = risk?.riskLevel ?? 'LOW';
    final color = _getRiskColor(level);
    final score = risk?.riskScore ?? 0;

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
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT RISK',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getRiskIcon(level), size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      level,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
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
                '$score',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              const Text(
                ' / 100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your current allergy flare-up risk index based on environmental pollen, dust & recent symptoms.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (risk != null && risk.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Text(
              'Key Contributing Factors:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...risk.contributingFactors.map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${factor.factor.toUpperCase()}: ${factor.reason}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ]
        ],
      ),
    );
  }
}
