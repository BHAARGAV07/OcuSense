import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<PatientProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _locationController = TextEditingController(text: profile?.locationName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final success = await patientProvider.updateProfile(
      displayName: _nameController.text.trim(),
      locationName: _locationController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
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
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (patientProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.riskHigh.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      patientProvider.errorMessage!,
                      style: const TextStyle(color: AppColors.riskHigh, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                Text('Patient Name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Display Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter display name' : null,
                ),
                const SizedBox(height: 20),

                Text('Location / Region Name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Chennai, TN',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter location' : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: patientProvider.isLoading ? null : _saveProfile,
                  child: patientProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
