import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/analysis_provider.dart';

class OutcomeFeedbackDialog extends StatefulWidget {
  final String? predictionId;

  const OutcomeFeedbackDialog({super.key, this.predictionId});

  @override
  State<OutcomeFeedbackDialog> createState() => _OutcomeFeedbackDialogState();
}

class _OutcomeFeedbackDialogState extends State<OutcomeFeedbackDialog> {
  bool _flareOccurred = false;
  String _severity = 'NONE';
  bool _rescueMedicationUsed = false;
  bool _doctorVisit = false;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    final success = await provider.submitOutcomeFeedback(
      predictionId: widget.predictionId,
      flareOccurred: _flareOccurred,
      symptomSeverity: _severity,
      rescueMedicationUsed: _rescueMedicationUsed,
      doctorVisit: _doctorVisit,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Outcome logged successfully. Thank you for contributing to research data!'
                : 'Failed to record outcome. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Record Actual Outcome',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Help evaluate OcuSense predictions by reporting what actually occurred during this window.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Question 1: Did a flare occur?
            const Text('1. Did an ocular allergy flare occur?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('No Flare')),
                    selected: !_flareOccurred,
                    selectedColor: AppColors.riskLow.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() {
                      _flareOccurred = false;
                      _severity = 'NONE';
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Yes, Flared')),
                    selected: _flareOccurred,
                    selectedColor: AppColors.riskHigh.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _flareOccurred = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_flareOccurred) ...[
              const Text('2. Peak Symptom Severity?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['MILD', 'MODERATE', 'SEVERE'].map((s) {
                  final isSel = _severity == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _severity = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Used rescue allergy drops / medication?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              value: _rescueMedicationUsed,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _rescueMedicationUsed = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required ophthalmologist / doctor visit?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              value: _doctorVisit,
              activeThumbColor: AppColors.riskHigh,
              onChanged: (v) => setState(() => _doctorVisit = v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observations (Optional)',
                hintText: 'e.g. Flare started after outdoor commute...',
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
