import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/symptom_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/symptom_selector.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  List<String> _selectedSymptoms = ['itching'];
  double _severityScore = 6.0;
  bool _symptomsIncreased = false;
  final _notesController = TextEditingController();

  final List<SymptomSelectorItem> _availableSymptoms = const [
    SymptomSelectorItem(id: 'itching', label: 'Itching', emoji: '👁️'),
    SymptomSelectorItem(id: 'redness', label: 'Redness', emoji: '🔴'),
    SymptomSelectorItem(id: 'watering', label: 'Watering', emoji: '💧'),
    SymptomSelectorItem(id: 'irritation', label: 'Irritation', emoji: '⚡'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getSeverityLabel(double score) {
    if (score <= 3) return 'LOW';
    if (score <= 7) return 'MODERATE';
    return 'HIGH';
  }

  Color _getSeverityColor(double score) {
    if (score <= 3) return AppColors.riskLow;
    if (score <= 7) return AppColors.riskModerate;
    return AppColors.riskHigh;
  }

  Future<void> _submitSymptoms() async {
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

    final success = await symptomProvider.logSymptoms(
      symptoms: _selectedSymptoms,
      severity: _getSeverityLabel(_severityScore),
      severityScore: _severityScore.toInt(),
      recentSymptomsIncreased: _symptomsIncreased,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      // Refresh risk engine calculation with new telemetry
      analysisProvider.fetchRiskAnalysis();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Symptom log saved successfully!'),
          backgroundColor: AppColors.riskLow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptomProvider = Provider.of<SymptomProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Symptoms'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (symptomProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.riskHigh.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    symptomProvider.errorMessage!,
                    style: const TextStyle(color: AppColors.riskHigh, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              Text('Select Symptoms Experienced', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Tap all symptoms that you are feeling today.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),

              SymptomSelector(
                items: _availableSymptoms,
                selectedIds: _selectedSymptoms,
                onChanged: (updated) {
                  setState(() {
                    _selectedSymptoms = updated;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Severity Score Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Severity Level', style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(_severityScore).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_severityScore.toInt()} / 10 (${_getSeverityLabel(_severityScore)})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(_severityScore),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getSeverityColor(_severityScore),
                  thumbColor: _getSeverityColor(_severityScore),
                  overlayColor: _getSeverityColor(_severityScore).withOpacity(0.2),
                ),
                child: Slider(
                  value: _severityScore,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  label: '${_severityScore.toInt()}',
                  onChanged: (val) {
                    setState(() {
                      _severityScore = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Recent Symptoms Increased Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Symptoms flare up recently?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check if your eye irritation has intensified over the last 24h.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _symptomsIncreased,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _symptomsIncreased = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Optional Notes
              Text('Additional Clinical Notes (Optional)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Woke up with itchy swollen eyelids after outdoor gardening...',
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: symptomProvider.isSubmitting ? null : _submitSymptoms,
                child: symptomProvider.isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Submit Symptom Telemetry'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
