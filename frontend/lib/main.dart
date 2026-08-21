import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/patient_service.dart';
import 'services/symptom_service.dart';
import 'services/habit_service.dart';
import 'services/analysis_service.dart';
import 'services/reminder_service.dart';
import 'services/cold_compress_service.dart';

import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/symptom_provider.dart';
import 'providers/care_provider.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/home/main_tab_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final patientService = PatientService(apiClient);
  final symptomService = SymptomService(apiClient);
  final habitService = HabitService(apiClient);
  final analysisService = AnalysisService(apiClient);
  final reminderService = ReminderService(apiClient);
  final coldCompressService = ColdCompressService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, apiClient)..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientProvider(patientService),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(analysisService),
        ),
        ChangeNotifierProvider(
          create: (_) => SymptomProvider(symptomService, habitService),
        ),
        ChangeNotifierProvider(
          create: (_) => CareProvider(reminderService, coldCompressService),
        ),
      ],
      child: const OcuSenseApp(),
    ),
  );
}

class OcuSenseApp extends StatelessWidget {
  const OcuSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OcuSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.status == AuthStatus.uninitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (auth.isAuthenticated) {
            return const MainTabNavigation();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}
