class PersonalizationProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? locationName;
  final double? locationLat;
  final double? locationLon;
  
  final int? age;
  final String? sex;
  final String? occupation;
  final bool previousAllergyHistory;
  final String typicalFlareFrequency;
  final String typicalSeasonalPattern;
  final bool dustSensitivity;
  final bool pollenSensitivity;
  final bool petExposure;
  final bool smokeExposure;
  final double outdoorActivityHours;
  final bool eyeRubbingTendency;
  final bool contactLensUse;
  final String? currentMedication;
  final bool isOnboarded;

  PersonalizationProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.locationName,
    this.locationLat,
    this.locationLon,
    this.age,
    this.sex,
    this.occupation,
    this.previousAllergyHistory = false,
    this.typicalFlareFrequency = 'Monthly',
    this.typicalSeasonalPattern = 'Spring/Summer',
    this.dustSensitivity = true,
    this.pollenSensitivity = true,
    this.petExposure = false,
    this.smokeExposure = false,
    this.outdoorActivityHours = 2.0,
    this.eyeRubbingTendency = false,
    this.contactLensUse = false,
    this.currentMedication,
    this.isOnboarded = false,
  });

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) {
    return PersonalizationProfile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      displayName: json['display_name'],
      locationName: json['location_name'],
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLon: (json['location_lon'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      sex: json['sex'],
      occupation: json['occupation'],
      previousAllergyHistory: json['previous_allergy_history'] ?? false,
      typicalFlareFrequency: json['typical_flare_frequency'] ?? 'Monthly',
      typicalSeasonalPattern: json['typical_seasonal_pattern'] ?? 'Spring/Summer',
      dustSensitivity: json['dust_sensitivity'] ?? true,
      pollenSensitivity: json['pollen_sensitivity'] ?? true,
      petExposure: json['pet_exposure'] ?? false,
      smokeExposure: json['smoke_exposure'] ?? false,
      outdoorActivityHours: (json['outdoor_activity_hours'] as num?)?.toDouble() ?? 2.0,
      eyeRubbingTendency: json['eye_rubbing_tendency'] ?? false,
      contactLensUse: json['contact_lens_use'] ?? false,
      currentMedication: json['current_medication'],
      isOnboarded: json['is_onboarded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'location_name': locationName,
      'location_lat': locationLat,
      'location_lon': locationLon,
      'age': age,
      'sex': sex,
      'occupation': occupation,
      'previous_allergy_history': previousAllergyHistory,
      'typical_flare_frequency': typicalFlareFrequency,
      'typical_seasonal_pattern': typicalSeasonalPattern,
      'dust_sensitivity': dustSensitivity,
      'pollen_sensitivity': pollenSensitivity,
      'pet_exposure': petExposure,
      'smoke_exposure': smokeExposure,
      'outdoor_activity_hours': outdoorActivityHours,
      'eye_rubbing_tendency': eyeRubbingTendency,
      'contact_lens_use': contactLensUse,
      'current_medication': currentMedication,
      'is_onboarded': isOnboarded,
    };
  }
}
