import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/cold_compress.dart';
import '../services/reminder_service.dart';
import '../services/cold_compress_service.dart';

class CareProvider extends ChangeNotifier {
  final ReminderService _reminderService;
  final ColdCompressService _coldCompressService;

  List<Reminder> _reminders = [];
  List<ColdCompressSession> _compressSessions = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Cold Compress Timer State
  Timer? _timer;
  int _timerSecondsRemaining = 300; // Default 5 mins
  int _initialSeconds = 300;
  bool _isTimerRunning = false;
  bool _isTimerCompleted = false;

  CareProvider(this._reminderService, this._coldCompressService);

  List<Reminder> get reminders => _reminders;
  List<ColdCompressSession> get compressSessions => _compressSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get timerSecondsRemaining => _timerSecondsRemaining;
  int get initialSeconds => _initialSeconds;
  bool get isTimerRunning => _isTimerRunning;
  bool get isTimerCompleted => _isTimerCompleted;

  Future<void> fetchCareData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reminders = await _reminderService.getReminders();
      _compressSessions = await _coldCompressService.getSessions();
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReminder({
    required String title,
    required String type,
    required String time,
    required String frequency,
  }) async {
    try {
      final rem = await _reminderService.createReminder(
        title: title,
        type: type,
        time: time,
        frequency: frequency,
      );
      _reminders.add(rem);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleReminder(String id, bool isEnabled) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updated = await _reminderService.updateReminder(id, isEnabled: isEnabled);
        _reminders[index] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _reminderService.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (_) {}
  }

  // Timer Methods
  void setTimerDuration(int seconds) {
    if (_isTimerRunning) return;
    _initialSeconds = seconds;
    _timerSecondsRemaining = seconds;
    _isTimerCompleted = false;
    notifyListeners();
  }

  void startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;
    _isTimerCompleted = false;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSecondsRemaining > 0) {
        _timerSecondsRemaining--;
        notifyListeners();
      } else {
        stopTimer();
        _isTimerCompleted = true;
        completeSession();
        notifyListeners();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  void pauseTimer() {
    stopTimer();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
    _timerSecondsRemaining = _initialSeconds;
    _isTimerCompleted = false;
    notifyListeners();
  }

  Future<void> completeSession() async {
    try {
      final session = await _coldCompressService.recordSession(
        durationSeconds: _initialSeconds - _timerSecondsRemaining,
        notes: 'Completed cold compress therapy',
      );
      _compressSessions.insert(0, session);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
