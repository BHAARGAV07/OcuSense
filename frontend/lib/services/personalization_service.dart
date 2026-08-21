import 'api_client.dart';
import '../models/personalization.dart';

class PersonalizationService {
  final ApiClient _apiClient;

  PersonalizationService(this._apiClient);

  Future<PersonalizationProfile> getProfile() async {
    final res = await _apiClient.get('/api/personalization');
    return PersonalizationProfile.fromJson(res);
  }

  Future<PersonalizationProfile> saveOnboarding(PersonalizationProfile profile) async {
    final res = await _apiClient.post('/api/personalization', body: profile.toJson());
    return PersonalizationProfile.fromJson(res);
  }

  Future<PersonalizationProfile> updateSettings(Map<String, dynamic> patchData) async {
    final res = await _apiClient.patch('/api/personalization', body: patchData);
    return PersonalizationProfile.fromJson(res);
  }
}
