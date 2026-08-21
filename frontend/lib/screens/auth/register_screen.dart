import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';
import '../home/main_tab_navigation.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);

    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Save display name & location address to patient profile
      await patientProvider.updateProfile(
        displayName: _nameController.text.trim(),
        locationName: _addressController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainTabNavigation()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Patient Account',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Register to start monitoring your eye health, symptoms, and localized triggers.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.riskHigh.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.riskHigh.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.riskHigh),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.riskHigh,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Patient Name
                Text('Patient Name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 18),

                // Email Address
                Text('Email Address', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'patient@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter email';
                    if (!val.contains('@')) return 'Enter valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                Text('Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Age & Mobile
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Age', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '28',
                              prefixIcon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mobile Number', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '+1 234...',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Location / Address
                Text('Location / Address', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'City / Region',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submitRegister,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Register'),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already registered? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login Here',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
