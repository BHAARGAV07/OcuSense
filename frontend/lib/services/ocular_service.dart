import 'api_client.dart';
import '../models/ocular_analysis.dart';

class OcularService {
  final ApiClient _apiClient;

  OcularService(this._apiClient);

  Future<OcularAnalysisResult> analyzeVideoBytes(List<int> bytes, String filename) async {
    final res = await _apiClient.uploadMultipart(
      '/api/ocular/analyze-video',
      fileField: 'video',
      fileBytes: bytes,
      filename: filename,
    );
    return OcularAnalysisResult.fromJson(res);
  }

  Future<OcularAnalysisResult> analyzeImageBytes(List<int> bytes, String filename) async {
    final res = await _apiClient.uploadMultipart(
      '/api/ocular/analyze-image',
      fileField: 'image',
      fileBytes: bytes,
      filename: filename,
    );
    return OcularAnalysisResult.fromJson(res);
  }
}
