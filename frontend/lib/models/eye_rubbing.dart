class EyeRubbingSummary {
  final int todayCount;
  final int totalCount;
  final String? lastEvent;

  EyeRubbingSummary({
    required this.todayCount,
    required this.totalCount,
    this.lastEvent,
  });

  factory EyeRubbingSummary.fromJson(Map<String, dynamic> json) {
    return EyeRubbingSummary(
      todayCount: json['today_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
      lastEvent: json['last_event'],
    );
  }
}
