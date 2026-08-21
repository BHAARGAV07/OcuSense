import 'api_client.dart';
import '../models/risk.dart';
import '../models/trigger.dart';

class AnalysisService {
  final ApiClient _apiClient;

  AnalysisService(this._apiClient);

  Future<RiskAnalysis> getRiskAnalysis({double lat = 13.0827, double lon = 80.2707}) async {
    final res = await _apiClient.get(
      '/api/analysis/risk',
      queryParams: {'lat': lat.toString(), 'lon': lon.toString()},
    );
    return RiskAnalysis.fromJson(res);
  }

  Future<List<TriggerAssociation>> getPersonalizedTriggers() async {
    final res = await _apiClient.get('/api/analysis/triggers');
    if (res is Map && res.containsKey('triggers') && res['triggers'] is List) {
      final list = res['triggers'] as List;
      return list.map((item) => TriggerAssociation.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<RiskHistoryItem>> getRiskHistory() async {
    final res = await _apiClient.get('/api/analysis/history');
    if (res is Map && res.containsKey('history') && res['history'] is List) {
      final list = res['history'] as List;
      return list.map((item) => RiskHistoryItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getCombinedData({double lat = 13.0827, double lon = 80.2707}) async {
    final res = await _apiClient.get(
      '/api/analysis/combined-data',
      queryParams: {'lat': lat.toString(), 'lon': lon.toString()},
    );
    return res as Map<String, dynamic>;
  }
}
