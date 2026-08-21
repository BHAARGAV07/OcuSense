import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';
import '../personalization/personalization_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final profile = patientProvider.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Avatar & Name Banner
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadowColor, blurRadius: 16, offset: Offset(0, 6))
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile?.displayName ?? 'Patient',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.locationName ?? 'Location Not Specified',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Details Card
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
                child: Column(
                  children: [
                    _buildProfileItem(Icons.person_outline, 'Display Name', profile?.displayName ?? 'N/A'),
                    const Divider(color: AppColors.divider),
                    _buildProfileItem(Icons.location_on_outlined, 'Address / Region', profile?.locationName ?? 'N/A'),
                    const Divider(color: AppColors.divider),
                    _buildProfileItem(
                      Icons.map_outlined,
                      'Coordinates',
                      profile?.locationLat != null ? '${profile?.locationLat}, ${profile?.locationLon}' : '13.0827, 80.2707',
                    ),
                    const Divider(color: AppColors.divider),
                    _buildProfileItem(
                      Icons.calendar_today_outlined,
                      'Member Since',
                      profile != null ? profile.createdAt.toString().split(' ')[0] : 'Today',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons: Edit Profile, Personalization & Logout
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalizationScreen(isEditing: true)),
                  );
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Personalization & Allergy History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () async {
                  final provider = Provider.of<PatientProvider>(context, listen: false);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                  if (mounted) {
                    provider.fetchProfile();
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Basic Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.riskHigh),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.riskHigh, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: AppColors.riskHigh),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
