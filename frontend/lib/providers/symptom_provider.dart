import 'package:flutter/material.dart';
import '../models/symptom.dart';
import '../models/habit.dart';
import '../models/eye_rubbing.dart';
import '../services/symptom_service.dart';
import '../services/habit_service.dart';
import '../services/api_client.dart';

class SymptomProvider extends ChangeNotifier {
  final SymptomService _symptomService;
  final HabitService _habitService;

  List<SymptomLog> _symptomLogs = [];
  List<HabitLog> _habitLogs = [];
  EyeRubbingSummary? _eyeRubbingSummary;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  SymptomProvider(this._symptomService, this._habitService);

  List<SymptomLog> get symptomLogs => _symptomLogs;
  List<HabitLog> get habitLogs => _habitLogs;
  EyeRubbingSummary? get eyeRubbingSummary => _eyeRubbingSummary;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _symptomLogs = await _symptomService.getSymptomLogs();
      _habitLogs = await _habitService.getHabitLogs();
      _eyeRubbingSummary = await _habitService.getEyeRubbingSummary();
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logSymptoms({
    required List<String> symptoms,
    required String severity,
    required int severityScore,
    bool recentSymptomsIncreased = false,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final log = await _symptomService.logSymptoms(
        symptoms: symptoms,
        severity: severity,
        severityScore: severityScore,
        recentSymptomsIncreased: recentSymptomsIncreased,
        notes: notes,
      );
      _symptomLogs.insert(0, log);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit symptom log.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logHabits({required List<String> habits, String? notes}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final log = await _habitService.logHabits(habits: habits, notes: notes);
      _habitLogs.insert(0, log);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit habit log.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logEyeRubbingEvent() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _eyeRubbingSummary = await _habitService.logEyeRubbingEvent();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to log eye rubbing event.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
