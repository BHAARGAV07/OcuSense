import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../services/api_client.dart';

class PatientProvider extends ChangeNotifier {
  final PatientService _patientService;

  PatientProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  PatientProvider(this._patientService);

  PatientProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _patientService.getMyProfile();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load profile details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? locationName,
    double? locationLat,
    double? locationLon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _patientService.updateMyProfile(
        displayName: displayName,
        locationName: locationName,
        locationLat: locationLat,
        locationLon: locationLon,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
