import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Visual Icon & Shield Hero
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'OcuSense',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Personalized Ocular Allergy & Risk Analytics',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'AI & Environmental Rule Engine',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
