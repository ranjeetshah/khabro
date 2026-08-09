/// Represents the authenticated user's latest known location.
class LocationModel {
  const LocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: json['accuracyMeters'] == null
          ? null
          : (json['accuracyMeters'] as num).toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'capturedAt': capturedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
