import 'api_client.dart';
import '../models/risk.dart';
import '../models/trigger.dart';

class AnalysisService {
  final ApiClient _apiClient;

  AnalysisService(this._apiClient);

  Future<RiskAnalysis> getRiskAnalysis({double? lat, double? lon}) async {
    final queryParams = <String, String>{};
    if (lat != null && lon != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lon'] = lon.toString();
    }
    final res = await _apiClient.get('/api/analysis/risk', queryParams: queryParams);
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

  Future<Map<String, dynamic>> getCombinedData({double? lat, double? lon}) async {
    final queryParams = <String, String>{};
    if (lat != null && lon != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lon'] = lon.toString();
    }
    final res = await _apiClient.get('/api/analysis/combined-data', queryParams: queryParams);
    return res as Map<String, dynamic>;
  }
}
