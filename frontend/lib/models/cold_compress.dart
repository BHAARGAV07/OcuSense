class ColdCompressSession {
  final String id;
  final String userId;
  final int durationSeconds;
  final bool completed;
  final String notes;
  final DateTime timestamp;

  ColdCompressSession({
    required this.id,
    required this.userId,
    required this.durationSeconds,
    required this.completed,
    required this.notes,
    required this.timestamp,
  });

  factory ColdCompressSession.fromJson(Map<String, dynamic> json) {
    return ColdCompressSession(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 300,
      completed: json['completed'] ?? true,
      notes: json['notes'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}
