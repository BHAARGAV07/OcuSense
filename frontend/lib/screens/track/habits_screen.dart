import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/symptom_provider.dart';
import '../../theme/app_colors.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final List<String> _selectedHabits = ['outdoor_activity'];
  final _notesController = TextEditingController();

  final List<Map<String, String>> _habitOptions = const [
    {'id': 'outdoor_activity', 'label': 'Outdoor Exposure', 'emoji': '🏞️', 'desc': 'Park, garden, or dusty streets'},
    {'id': 'eye_rubbing', 'label': 'Frequent Eye Rubbing', 'emoji': '👁️', 'desc': 'Mechanical friction factor'},
    {'id': 'pet_contact', 'label': 'Pet Dander Exposure', 'emoji': '🐕', 'desc': 'Dogs, cats, or animals'},
    {'id': 'food_histamine', 'label': 'High Histamine Foods', 'emoji': '🧀', 'desc': 'Aged cheese, fermented food, seafood'},
    {'id': 'late_sleep', 'label': 'Sleep Deprivation', 'emoji': '🌙', 'desc': 'Under 6 hours of rest'},
    {'id': 'screen_time', 'label': 'Prolonged Screen Time', 'emoji': '💻', 'desc': 'High digital eye strain'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitHabits() async {
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
    final success = await symptomProvider.logHabits(
      habits: _selectedHabits,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Habit log saved successfully!'),
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
        title: const Text('Food & Lifestyle Habits'),
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
              Text('Log Daily Exposure & Diet', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Track environmental exposures and lifestyle triggers that exacerbate ocular histamine release.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _habitOptions.length,
                itemBuilder: (context, index) {
                  final item = _habitOptions[index];
                  final isSelected = _selectedHabits.contains(item['id']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedHabits.remove(item['id']);
                          } else {
                            _selectedHabits.add(item['id']!);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(item['emoji']!, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['desc']!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedHabits.add(item['id']!);
                                  } else {
                                    _selectedHabits.remove(item['id']);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              Text('Optional Lifestyle Notes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ate seafood lunch, walked near dusty construction area...',
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: symptomProvider.isSubmitting ? null : _submitHabits,
                child: symptomProvider.isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Save Habit Telemetry'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
