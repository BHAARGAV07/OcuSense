import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/symptom_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class SymptomTrendsScreen extends StatefulWidget {
  const SymptomTrendsScreen({super.key});

  @override
  State<SymptomTrendsScreen> createState() => _SymptomTrendsScreenState();
}

class _SymptomTrendsScreenState extends State<SymptomTrendsScreen> {
  int _selectedDaysFilter = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SymptomProvider>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final symptomProvider = Provider.of<SymptomProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Symptom Trends'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => symptomProvider.fetchLogs(),
          child: _buildBody(symptomProvider),
        ),
      ),
    );
  }

  Widget _buildBody(SymptomProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget(message: 'Loading symptom trend telemetry...');
    }

    final logs = provider.symptomLogs;

    if (logs.isEmpty) {
      return CustomErrorWidget(
        message: 'No symptom history yet. Start by logging your symptoms.',
        onRetry: () => provider.fetchLogs(),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Timeline', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [7, 14, 30].map((days) {
                  final isSelected = _selectedDaysFilter == days;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: ChoiceChip(
                      label: Text('${days}D'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedDaysFilter = days;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Recent Symptom Records', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowColor, blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Score: ${log.severityScore}/10 (${log.severity})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: log.symptoms.map((symptom) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                symptom.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
