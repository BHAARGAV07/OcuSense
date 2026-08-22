import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/risk_card.dart';
import '../track/symptoms_screen.dart';
import '../track/habits_screen.dart';
import '../track/eye_rubbing_screen.dart';
import '../insights/triggers_screen.dart';
import '../check_eyes/eye_check_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      Provider.of<PatientProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _loadDashboardData() async {
    Position? position;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition();
        }
      }
    } catch (_) {}

    if (!mounted) return;
    await context.read<AnalysisProvider>().fetchDashboardData(
          lat: position?.latitude,
          lon: position?.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final analysisProvider = Provider.of<AnalysisProvider>(context);

    final patientName = patientProvider.profile?.displayName ?? 'Patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadDashboardData(),
              patientProvider.fetchProfile(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Day 👋',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          patientName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadowColor, blurRadius: 10)
                        ],
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Risk Card Component
                RiskCard(
                  riskAnalysis: analysisProvider.riskAnalysis,
                  mlPrediction: analysisProvider.latestPrediction,
                  isLoading: analysisProvider.isLoadingRisk,
                  errorMessage: analysisProvider.riskErrorMessage,
                  onRetry: () => _loadDashboardData(),
                  onCheckEyes: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeCheckFlowScreen()));
                  },
                ),
                const SizedBox(height: 20),

                // CHECK MY EYES PROMINENT HERO CTA
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeCheckFlowScreen()));
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Check My Eyes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '10–20s video capture • Objective CV redness • Flare probability',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Actions Section
                Text(
                  'QUICK ACTIONS',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        context,
                        icon: Icons.sick_outlined,
                        title: 'Log Symptoms',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomsScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionTile(
                        context,
                        icon: Icons.restaurant_outlined,
                        title: 'Log Habits',
                        color: AppColors.accent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen()));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEyeRubbingQuickTile(context),

                const SizedBox(height: 28),

                // Environmental Sensor Readings Summary Card
                Text(
                  'ENVIRONMENTAL SNAPSHOT',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 14),
                _buildEnvironmentalSummaryCard(context, analysisProvider.combinedData),

                const SizedBox(height: 28),

                // Insights Quick Action
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(24),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Personalized Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover your primary environmental allergy triggers.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TriggersScreen()));
                        },
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeRubbingQuickTile(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeRubbingScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.riskModerate.withValues(alpha: 0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.riskModerate.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.riskModerate.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('👁️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Eye Rubbing Tracker',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Single-tap log to track mechanical friction events',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.riskModerate, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalSummaryCard(BuildContext context, Map<String, dynamic>? data) {
    final envApi = data?['environment_api'] as Map<String, dynamic>?;
    final envHw = data?['environment_hardware'] as Map<String, dynamic>?;

    final dust = envHw?['dust'] ?? 421;
    final humidity = envHw?['humidity'] ?? envApi?['humidity'] ?? 76;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEnvMetric('🌱 Pollen', 'Elevated', AppColors.riskModerate),
          const SizedBox(
            height: 40,
            child: VerticalDivider(color: AppColors.divider),
          ),
          _buildEnvMetric('🌫️ Dust', '$dust µg', AppColors.riskHigh),
          const SizedBox(
            height: 40,
            child: VerticalDivider(color: AppColors.divider),
          ),
          _buildEnvMetric('💧 Humidity', '$humidity%', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildEnvMetric(String label, String value, Color color) {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
