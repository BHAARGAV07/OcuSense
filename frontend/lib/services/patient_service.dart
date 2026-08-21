import 'api_client.dart';
import '../models/patient.dart';

class PatientService {
  final ApiClient _apiClient;

  PatientService(this._apiClient);

  Future<PatientProfile> getMyProfile() async {
    final res = await _apiClient.get('/api/patients/me');
    return PatientProfile.fromJson(res);
  }

  Future<PatientProfile> updateMyProfile({
    String? displayName,
    String? locationName,
    double? locationLat,
    double? locationLon,
  }) async {
    final payload = <String, dynamic>{};
    if (displayName != null) payload['display_name'] = displayName;
    if (locationName != null) payload['location_name'] = locationName;
    if (locationLat != null) payload['location_lat'] = locationLat;
    if (locationLon != null) payload['location_lon'] = locationLon;

    final res = await _apiClient.patch('/api/patients/me', body: payload);
    return PatientProfile.fromJson(res);
  }
}
