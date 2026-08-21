import 'api_client.dart';
import '../models/symptom.dart';

class SymptomService {
  final ApiClient _apiClient;

  SymptomService(this._apiClient);

  Future<SymptomLog> logSymptoms({
    required List<String> symptoms,
    required String severity,
    required int severityScore,
    bool recentSymptomsIncreased = false,
    String? notes,
  }) async {
    final payload = {
      'symptoms': symptoms,
      'severity': severity,
      'severity_score': severityScore,
      'recent_symptoms_increased': recentSymptomsIncreased,
      'notes': notes,
    };
    final res = await _apiClient.post('/api/symptoms', body: payload);
    return SymptomLog.fromJson(res);
  }

  Future<List<SymptomLog>> getSymptomLogs() async {
    final res = await _apiClient.get('/api/symptoms');
    if (res is List) {
      return res.map((item) => SymptomLog.fromJson(item)).toList();
    }
    return [];
  }
}
