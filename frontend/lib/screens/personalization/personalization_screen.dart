import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/personalization_service.dart';
import '../../models/personalization.dart';
import '../home/main_tab_navigation.dart';

class PersonalizationScreen extends StatefulWidget {
  final bool isEditing;
  const PersonalizationScreen({super.key, this.isEditing = false});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personalizationService = PersonalizationService(ApiClient());

  bool _isLoading = false;
  bool _isFetching = true;

  // Basic Profile
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _occupationController = TextEditingController();
  int _age = 28;
  String _sex = 'Female';

  // Ocular Allergy History
  bool _previousAllergyHistory = true;
  String _flareFrequency = 'Monthly';
  String _seasonalPattern = 'Spring/Summer';

  // Exposure History
  bool _dustSensitivity = true;
  bool _pollenSensitivity = true;
  bool _petExposure = false;
  bool _smokeExposure = false;

  // Behavioural Information
  double _outdoorHours = 2.5;
  bool _eyeRubbingTendency = false;
  bool _contactLensUse = false;

  // Medication
  final _medicationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _occupationController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _personalizationService.getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile.displayName ?? '';
          _cityController.text = profile.locationName ?? '';
          _occupationController.text = profile.occupation ?? '';
          _age = profile.age ?? 28;
          _sex = profile.sex ?? 'Female';
          _previousAllergyHistory = profile.previousAllergyHistory;
          _flareFrequency = profile.typicalFlareFrequency;
          _seasonalPattern = profile.typicalSeasonalPattern;
          _dustSensitivity = profile.dustSensitivity;
          _pollenSensitivity = profile.pollenSensitivity;
          _petExposure = profile.petExposure;
          _smokeExposure = profile.smokeExposure;
          _outdoorHours = profile.outdoorActivityHours;
          _eyeRubbingTendency = profile.eyeRubbingTendency;
          _contactLensUse = profile.contactLensUse;
          _medicationController.text = profile.currentMedication ?? '';
          _isFetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = PersonalizationProfile(
        id: '',
        userId: '',
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        locationName: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        age: _age,
        sex: _sex,
        previousAllergyHistory: _previousAllergyHistory,
        typicalFlareFrequency: _flareFrequency,
        typicalSeasonalPattern: _seasonalPattern,
        dustSensitivity: _dustSensitivity,
        pollenSensitivity: _pollenSensitivity,
        petExposure: _petExposure,
        smokeExposure: _smokeExposure,
        outdoorActivityHours: _outdoorHours,
        eyeRubbingTendency: _eyeRubbingTendency,
        contactLensUse: _contactLensUse,
        currentMedication: _medicationController.text.trim().isNotEmpty ? _medicationController.text.trim() : null,
        isOnboarded: true,
      );

      await _personalizationService.saveOnboarding(profile);

      if (mounted) {
        if (widget.isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personalization profile updated successfully.')),
          );
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainTabNavigation()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Personalization' : 'Personalize Your Care'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Environmental factors (PM2.5, PM10, AQI, humidity & pollen) are fetched automatically. '
                          'We only need your baseline characteristics to personalize your AI risk model.',
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 1: BASIC PROFILE
                _buildSectionHeader('1. Basic Profile', Icons.person_outline),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name / Preferred Name',
                          hintText: 'e.g. John Doe',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City / Region',
                                hintText: 'e.g. Chennai',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _occupationController,
                              decoration: const InputDecoration(
                                labelText: 'Occupation (Optional)',
                                hintText: 'e.g. Engineer',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Age: $_age years', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Slider(
                                  value: _age.toDouble(),
                                  min: 5,
                                  max: 95,
                                  divisions: 90,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _age = val.round()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sex', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                value: _sex,
                                items: ['Female', 'Male', 'Other'].map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) => setState(() => _sex = val ?? 'Female'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 2: OCULAR ALLERGY HISTORY
                _buildSectionHeader('2. Ocular Allergy History', Icons.visibility_outlined),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('History of Allergic Conjunctivitis / Itchy Eyes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Prior clinician diagnosis or recurrent eye allergies', style: TextStyle(fontSize: 12)),
                        value: _previousAllergyHistory,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _previousAllergyHistory = val),
                      ),
                      if (_previousAllergyHistory) ...[
                        const Divider(height: 20),
                        const Text('Typical Flare Frequency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Frequent', 'Monthly', 'Seasonal', 'Rare'].map((freq) {
                            final isSelected = _flareFrequency == freq;
                            return ChoiceChip(
                              label: Text(freq),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              onSelected: (_) => setState(() => _flareFrequency = freq),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text('Predominant Seasonal Pattern', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Spring/Summer', 'Monsoon', 'Winter', 'All Year'].map((season) {
                            final isSelected = _seasonalPattern == season;
                            return ChoiceChip(
                              label: Text(season),
                              selected: isSelected,
                              selectedColor: AppColors.accent.withValues(alpha: 0.2),
                              onSelected: (_) => setState(() => _seasonalPattern = season),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 3: EXPOSURE & SENSITIVITY
                _buildSectionHeader('3. Exposure Sensitivities', Icons.grass_outlined),
                _buildCard(
                  child: Column(
                    children: [
                      _buildCheckboxRow('Dust & Indoor Allergens', _dustSensitivity, (val) => setState(() => _dustSensitivity = val)),
                      const Divider(height: 12),
                      _buildCheckboxRow('Pollen & Flowering Plants', _pollenSensitivity, (val) => setState(() => _pollenSensitivity = val)),
                      const Divider(height: 12),
                      _buildCheckboxRow('Pet Dander Exposure', _petExposure, (val) => setState(() => _petExposure = val)),
                      const Divider(height: 12),
                      _buildCheckboxRow('Smoke & Heavy Traffic Exhaust', _smokeExposure, (val) => setState(() => _smokeExposure = val)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 4: BEHAVIOURAL HABITS
                _buildSectionHeader('4. Daily Habits', Icons.directions_walk_outlined),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approximate Daily Outdoor Time: ${_outdoorHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Slider(
                        value: _outdoorHours,
                        min: 0.0,
                        max: 12.0,
                        divisions: 24,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _outdoorHours = val),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Habitual Eye Rubbing Tendency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Do you frequently rub or touch your eyes when irritated?', style: TextStyle(fontSize: 12)),
                        value: _eyeRubbingTendency,
                        activeThumbColor: AppColors.riskModerate,
                        onChanged: (val) => setState(() => _eyeRubbingTendency = val),
                      ),
                      const Divider(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Contact Lens Wearer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        value: _contactLensUse,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _contactLensUse = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 5: MEDICATION
                _buildSectionHeader('5. Medication (Optional)', Icons.medication_outlined),
                _buildCard(
                  child: TextFormField(
                    controller: _medicationController,
                    decoration: const InputDecoration(
                      labelText: 'Current Allergy Drops / Prescriptions',
                      hintText: 'e.g. Olopatadine 0.1%, Artificial Tears',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // SAVE BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.isEditing ? 'Save Changes' : 'SAVE & CONTINUE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: child,
    );
  }

  Widget _buildCheckboxRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Checkbox(
          value: value,
          activeColor: AppColors.primary,
          onChanged: (val) => onChanged(val ?? false),
        ),
      ],
    );
  }
}
