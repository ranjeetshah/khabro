import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/features/location/data/location_acquisition.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission,
    this.position,
    this.positionError,
  });

  bool serviceEnabled;
  LocationPermission permission;
  LocationPermission? requestedPermission;
  Position? position;
  Object? positionError;
  bool requestPermissionCalled = false;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalled = true;
    return requestedPermission ?? permission;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    if (positionError != null) {
      return Future<Position>.error(positionError!);
    }
    return Future<Position>.value(position!);
  }
}

Position testPosition() {
  return Position(
    latitude: 28.7041,
    longitude: 77.1025,
    timestamp: DateTime.parse('2026-08-09T08:00:00.000Z'),
    accuracy: 25,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  group('GeolocatorLocationProvider', () {
    test('successfully acquires a current location', () async {
      final platform = FakeGeolocatorPlatform(position: testPosition());
      final provider = GeolocatorLocationProvider(platform: platform);

      final location = await provider.getCurrentLocation();

      expect(location.latitude, 28.7041);
      expect(location.longitude, 77.1025);
      expect(location.accuracyMeters, 25);
      expect(platform.requestPermissionCalled, isFalse);
    });

    test('requests and then reports denied permission', () async {
      final platform = FakeGeolocatorPlatform(
        permission: LocationPermission.denied,
        requestedPermission: LocationPermission.denied,
        position: testPosition(),
      );
      final provider = GeolocatorLocationProvider(platform: platform);

      await expectLater(
        provider.getCurrentLocation(),
        throwsA(
          isA<LocationAcquisitionException>().having(
            (error) => error.failure,
            'failure',
            LocationAcquisitionFailure.permissionDenied,
          ),
        ),
      );
      expect(platform.requestPermissionCalled, isTrue);
    });

    test('reports permanently denied permission', () async {
      final provider = GeolocatorLocationProvider(
        platform: FakeGeolocatorPlatform(
          permission: LocationPermission.deniedForever,
        ),
      );

      await expectLater(
        provider.getCurrentLocation(),
        throwsA(
          isA<LocationAcquisitionException>().having(
            (error) => error.failure,
            'failure',
            LocationAcquisitionFailure.permissionDeniedForever,
          ),
        ),
      );
    });

    test('reports disabled location services', () async {
      final provider = GeolocatorLocationProvider(
        platform: FakeGeolocatorPlatform(serviceEnabled: false),
      );

      await expectLater(
        provider.getCurrentLocation(),
        throwsA(
          isA<LocationAcquisitionException>().having(
            (error) => error.failure,
            'failure',
            LocationAcquisitionFailure.serviceDisabled,
          ),
        ),
      );
    });

    test('reports timeout', () async {
      final provider = GeolocatorLocationProvider(
        platform: FakeGeolocatorPlatform(
          position: testPosition(),
          positionError: TimeoutException('timed out'),
        ),
      );

      await expectLater(
        provider.getCurrentLocation(),
        throwsA(
          isA<LocationAcquisitionException>().having(
            (error) => error.failure,
            'failure',
            LocationAcquisitionFailure.timeout,
          ),
        ),
      );
    });

    test('reports unavailable location', () async {
      final provider = GeolocatorLocationProvider(
        platform: FakeGeolocatorPlatform(
          position: testPosition(),
          positionError: StateError('unavailable'),
        ),
      );

      await expectLater(
        provider.getCurrentLocation(),
        throwsA(
          isA<LocationAcquisitionException>().having(
            (error) => error.failure,
            'failure',
            LocationAcquisitionFailure.unavailable,
          ),
        ),
      );
    });
  });
}
