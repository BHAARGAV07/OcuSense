class Reminder {
  final String id;
  final String userId;
  final String title;
  final String type; // EYE_DROPS, COLD_COMPRESS, CUSTOM
  final String time;
  final String frequency;
  final bool isEnabled;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.time,
    required this.frequency,
    required this.isEnabled,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? 'Care Reminder',
      type: json['type'] ?? 'EYE_DROPS',
      time: json['time'] ?? '08:00 AM',
      frequency: json['frequency'] ?? 'Daily',
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'time': time,
      'frequency': frequency,
      'is_enabled': isEnabled,
    };
  }
}
