import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../home/main_tab_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabNavigation()),
        (route) => false,
      );
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
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to view your personalized risk index and environmental insights.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

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

                // Email Field
                Text(
                  'Email Address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'patient@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                    if (!val.contains('@')) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'Password',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submitLogin,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Register Now',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
