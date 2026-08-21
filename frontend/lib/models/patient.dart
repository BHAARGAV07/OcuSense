class PatientProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? locationName;
  final double? locationLat;
  final double? locationLon;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.locationName,
    this.locationLat,
    this.locationLon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      displayName: json['display_name'],
      locationName: json['location_name'],
      locationLat: json['location_lat'] != null ? (json['location_lat'] as num).toDouble() : null,
      locationLon: json['location_lon'] != null ? (json['location_lon'] as num).toDouble() : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'location_name': locationName,
      'location_lat': locationLat,
      'location_lon': locationLon,
    };
  }
}
