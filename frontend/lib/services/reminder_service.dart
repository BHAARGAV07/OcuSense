import 'api_client.dart';
import '../models/reminder.dart';

class ReminderService {
  final ApiClient _apiClient;

  ReminderService(this._apiClient);

  Future<List<Reminder>> getReminders() async {
    final res = await _apiClient.get('/api/reminders');
    if (res is List) {
      return res.map((item) => Reminder.fromJson(item)).toList();
    }
    return [];
  }

  Future<Reminder> createReminder({
    required String title,
    required String type,
    required String time,
    required String frequency,
  }) async {
    final payload = {
      'title': title,
      'type': type,
      'time': time,
      'frequency': frequency,
      'is_enabled': true,
    };
    final res = await _apiClient.post('/api/reminders', body: payload);
    return Reminder.fromJson(res);
  }

  Future<Reminder> updateReminder(String id, {bool? isEnabled, String? time}) async {
    final payload = <String, dynamic>{};
    if (isEnabled != null) payload['is_enabled'] = isEnabled;
    if (time != null) payload['time'] = time;

    final res = await _apiClient.patch('/api/reminders/$id', body: payload);
    return Reminder.fromJson(res);
  }

  Future<void> deleteReminder(String id) async {
    await _apiClient.delete('/api/reminders/$id');
  }
}
