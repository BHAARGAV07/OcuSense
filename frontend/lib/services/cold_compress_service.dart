import 'api_client.dart';
import '../models/cold_compress.dart';

class ColdCompressService {
  final ApiClient _apiClient;

  ColdCompressService(this._apiClient);

  Future<ColdCompressSession> recordSession({required int durationSeconds, String notes = ''}) async {
    final payload = {
      'duration_seconds': durationSeconds,
      'completed': true,
      'notes': notes,
    };
    final res = await _apiClient.post('/api/cold-compress', body: payload);
    return ColdCompressSession.fromJson(res);
  }

  Future<List<ColdCompressSession>> getSessions() async {
    final res = await _apiClient.get('/api/cold-compress');
    if (res is List) {
      return res.map((item) => ColdCompressSession.fromJson(item)).toList();
    }
    return [];
  }
}
