import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_widget.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleController = TextEditingController();
  String _selectedType = 'EYE_DROPS';
  String _selectedTime = '08:00 AM';
  final String _selectedFreq = 'Daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CareProvider>(context, listen: false).fetchCareData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showAddReminderModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Care Reminder', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'e.g. Evening Antihistamine Drops',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'EYE_DROPS', child: Text('Eye Drops')),
                        DropdownMenuItem(value: 'COLD_COMPRESS', child: Text('Cold Compress')),
                        DropdownMenuItem(value: 'CUSTOM', child: Text('Custom Alert')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTime,
                      decoration: const InputDecoration(labelText: 'Schedule Time'),
                      items: const [
                        DropdownMenuItem(value: '08:00 AM', child: Text('08:00 AM')),
                        DropdownMenuItem(value: '02:00 PM', child: Text('02:00 PM')),
                        DropdownMenuItem(value: '08:00 PM', child: Text('08:00 PM')),
                        DropdownMenuItem(value: '10:00 PM', child: Text('10:00 PM')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTime = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) return;
                  final careProvider = Provider.of<CareProvider>(context, listen: false);
                  final nav = Navigator.of(context);
                  await careProvider.addReminder(
                    title: _titleController.text.trim(),
                    type: _selectedType,
                    time: _selectedTime,
                    frequency: _selectedFreq,
                  );
                  _titleController.clear();
                  if (mounted) nav.pop();
                },
                child: const Text('Save Reminder'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final careProvider = Provider.of<CareProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Care Reminders'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => careProvider.fetchCareData(),
          child: _buildBody(careProvider),
        ),
      ),
    );
  }

  Widget _buildBody(CareProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget(message: 'Loading reminders...');
    }

    final reminders = provider.reminders;

    if (reminders.isEmpty) {
      return const Center(
        child: Text('No care reminders configured. Tap + to add one.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final item = reminders[index];
        final isDrops = item.type == 'EYE_DROPS';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(color: AppColors.shadowColor, blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDrops ? AppColors.primary : AppColors.accent).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDrops ? Icons.water_drop_outlined : Icons.ac_unit_rounded,
                  color: isDrops ? AppColors.primary : AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.time}  •  ${item.frequency}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  provider.toggleReminder(item.id, val);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => provider.deleteReminder(item.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
