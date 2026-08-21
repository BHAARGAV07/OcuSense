import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analysis_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trigger_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class TriggersScreen extends StatefulWidget {
  const TriggersScreen({super.key});

  @override
  State<TriggersScreen> createState() => _TriggersScreenState();
}

class _TriggersScreenState extends State<TriggersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalysisProvider>(context, listen: false).fetchTriggers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisProvider = Provider.of<AnalysisProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Potential Triggers'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => analysisProvider.fetchTriggers(),
          child: _buildBody(analysisProvider),
        ),
      ),
    );
  }

  Widget _buildBody(AnalysisProvider provider) {
    if (provider.isLoadingTriggers) {
      return const LoadingWidget(message: 'Calculating personalized trigger associations...');
    }

    if (provider.triggerErrorMessage != null) {
      return CustomErrorWidget(
        message: provider.triggerErrorMessage!,
        onRetry: () => provider.fetchTriggers(),
      );
    }

    if (provider.triggers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.bubble_chart_outlined, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No Trigger Data Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Continue logging daily symptoms and habits to build personalized correlation models.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personalized Trigger Correlations', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Derived from real-time FastAPI rule engine associations between symptoms and environmental factors.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          ...provider.triggers.map((trigger) => TriggerCard(trigger: trigger)),
        ],
      ),
    );
  }
}
