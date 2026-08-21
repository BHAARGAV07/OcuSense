import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'triggers_screen.dart';
import 'risk_history_screen.dart';
import 'symptom_trends_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rule-Based Engine Insights', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Explore trigger correlations, risk history trends, and localized environmental forecasts.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              _buildInsightTile(
                context,
                title: 'Potential Triggers',
                subtitle: 'Personalized trigger associations, lift ratios & confidence levels',
                icon: Icons.bubble_chart_outlined,
                color: AppColors.riskModerate,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TriggersScreen()));
                },
              ),
              const SizedBox(height: 16),

              _buildInsightTile(
                context,
                title: 'Risk History',
                subtitle: 'Historical risk score progression & daily classification records',
                icon: Icons.timeline_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskHistoryScreen()));
                },
              ),
              const SizedBox(height: 16),

              _buildInsightTile(
                context,
                title: 'Symptom Trends',
                subtitle: 'Track itching, redness, watering & severity trends over time',
                icon: Icons.show_chart_rounded,
                color: AppColors.accent,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomTrendsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 16,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
