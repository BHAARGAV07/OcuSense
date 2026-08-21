import 'api_client.dart';
import '../models/prediction.dart';

class PredictionService {
  final ApiClient _apiClient;

  PredictionService(this._apiClient);

  Future<MLPredictionResult> generatePrediction({
    required Map<String, dynamic> canonicalFeatures,
    String? engine,
  }) async {
    final res = await _apiClient.post(
      '/api/prediction',
      body: {
        'features': canonicalFeatures,
        'engine': engine,
      },
    );
    return MLPredictionResult.fromJson(res);
  }

  Future<PredictionComparisonResult> compareEngines({double lat = 13.0827, double lon = 80.2707}) async {
    final res = await _apiClient.get(
      '/api/prediction/compare',
      queryParams: {'lat': lat.toString(), 'lon': lon.toString()},
    );
    return PredictionComparisonResult.fromJson(res);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await _apiClient.get('/api/prediction/history');
    if (res is Map && res.containsKey('history') && res['history'] is List) {
      return List<Map<String, dynamic>>.from(res['history']);
    }
    return [];
  }

  Future<bool> submitOutcomeFeedback({
    String? predictionId,
    required bool flareOccurred,
    String symptomSeverity = 'NONE',
    bool rescueMedicationUsed = false,
    bool doctorVisit = false,
    String? notes,
  }) async {
    await _apiClient.post(
      '/api/prediction/outcome',
      body: {
        'prediction_id': predictionId,
        'flare_occurred': flareOccurred,
        'symptom_severity': symptomSeverity,
        'rescue_medication_used': rescueMedicationUsed,
        'doctor_visit': doctorVisit,
        'notes': notes,
      },
    );
    return true;
  }
}
