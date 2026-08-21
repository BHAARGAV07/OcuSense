import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/symptom_provider.dart';
import '../../theme/app_colors.dart';

class EyeRubbingScreen extends StatefulWidget {
  const EyeRubbingScreen({super.key});

  @override
  State<EyeRubbingScreen> createState() => _EyeRubbingScreenState();
}

class _EyeRubbingScreenState extends State<EyeRubbingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SymptomProvider>(context, listen: false).fetchLogs();
    });
  }

  Future<void> _logEvent() async {
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
    final success = await symptomProvider.logEyeRubbingEvent();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Eye rubbing event recorded! Stay mindful to prevent micro-trauma.'),
          backgroundColor: AppColors.riskModerate,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptomProvider = Provider.of<SymptomProvider>(context);
    final todayCount = symptomProvider.eyeRubbingSummary?.todayCount ?? 0;
    final totalCount = symptomProvider.eyeRubbingSummary?.totalCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eye-Rubbing Tracker'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                'Mechanical Friction Telemetry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Eye rubbing releases mast cell histamine and causes corneal friction. Tap the button every time you catch yourself rubbing your eyes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),

              // Large Central Interactive Button
              GestureDetector(
                onTap: symptomProvider.isSubmitting ? null : _logEvent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.riskModerate, Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.riskModerate.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👁️', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 10),
                        symptomProvider.isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'I Rubbed\nMy Eyes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Real-time Event Counter Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowColor, blurRadius: 12)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCounterCol("Today's Events", '$todayCount', AppColors.riskModerate),
                    const SizedBox(
                      height: 40,
                      child: VerticalDivider(color: AppColors.divider),
                    ),
                    _buildCounterCol('Total Recorded', '$totalCount', AppColors.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
