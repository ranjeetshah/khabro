import 'dart:async';

import 'package:geolocator/geolocator.dart';

class AcquiredLocation {
  const AcquiredLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
}

enum LocationAcquisitionFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unavailable,
}

class LocationAcquisitionException implements Exception {
  const LocationAcquisitionException(this.failure, this.message);

  final LocationAcquisitionFailure failure;
  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationProvider {
  Future<AcquiredLocation> getCurrentLocation();
}

class GeolocatorLocationProvider implements LocationProvider {
  GeolocatorLocationProvider({
    GeolocatorPlatform? platform,
    this.timeout = const Duration(seconds: 15),
  }) : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;
  final Duration timeout;

  @override
  Future<AcquiredLocation> getCurrentLocation() async {
    try {
      final serviceEnabled = await _platform.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationAcquisitionException(
          LocationAcquisitionFailure.serviceDisabled,
          'Location services are disabled. Please enable them and try again.',
        );
      }

      var permission = await _platform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _platform.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationAcquisitionException(
          LocationAcquisitionFailure.permissionDenied,
          'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationAcquisitionException(
          LocationAcquisitionFailure.permissionDeniedForever,
          'Location permission is permanently denied. Please enable it in settings.',
        );
      }

      final position = await _platform.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      return AcquiredLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
      );
    } on LocationAcquisitionException {
      rethrow;
    } on TimeoutException {
      throw const LocationAcquisitionException(
        LocationAcquisitionFailure.timeout,
        'Location request timed out. Please try again.',
      );
    } on LocationServiceDisabledException {
      throw const LocationAcquisitionException(
        LocationAcquisitionFailure.serviceDisabled,
        'Location services are disabled. Please enable them and try again.',
      );
    } on PermissionDeniedException {
      throw const LocationAcquisitionException(
        LocationAcquisitionFailure.permissionDenied,
        'Location permission was denied.',
      );
    } catch (_) {
      throw const LocationAcquisitionException(
        LocationAcquisitionFailure.unavailable,
        'Your location is currently unavailable. Please try again.',
      );
    }
  }
}
