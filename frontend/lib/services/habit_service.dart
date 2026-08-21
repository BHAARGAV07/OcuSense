import 'api_client.dart';
import '../models/habit.dart';
import '../models/eye_rubbing.dart';

class HabitService {
  final ApiClient _apiClient;

  HabitService(this._apiClient);

  Future<HabitLog> logHabits({required List<String> habits, String? notes}) async {
    final payload = {
      'habits': habits,
      'notes': notes,
    };
    final res = await _apiClient.post('/api/habits', body: payload);
    return HabitLog.fromJson(res);
  }

  Future<List<HabitLog>> getHabitLogs() async {
    final res = await _apiClient.get('/api/habits');
    if (res is List) {
      return res.map((item) => HabitLog.fromJson(item)).toList();
    }
    return [];
  }

  Future<EyeRubbingSummary> logEyeRubbingEvent() async {
    final res = await _apiClient.post('/api/eye-rubbing/events');
    return EyeRubbingSummary.fromJson(res);
  }

  Future<EyeRubbingSummary> getEyeRubbingSummary() async {
    final res = await _apiClient.get('/api/eye-rubbing/events');
    return EyeRubbingSummary.fromJson(res);
  }
}
