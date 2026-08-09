import 'locality_model.dart';

/// Represents the authenticated user's latest known location.
class LocationModel {
  const LocationModel({
    required this.id,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
    this.locality,
  });

  final String id;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LocalityModel? locality;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      latitude: json['latitude'] == null
          ? null
          : (json['latitude'] as num).toDouble(),
      longitude: json['longitude'] == null
          ? null
          : (json['longitude'] as num).toDouble(),
      accuracyMeters: json['accuracyMeters'] == null
          ? null
          : (json['accuracyMeters'] as num).toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      locality: json['locality'] == null
          ? null
          : LocalityModel.fromJson(json['locality'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'capturedAt': capturedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (locality != null) json['locality'] = locality!.toJson();
    return json;
  }
}
