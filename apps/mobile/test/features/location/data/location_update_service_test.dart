import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/data/location_acquisition.dart';
import 'package:mobile/features/location/data/locality_model.dart';
import 'package:mobile/features/location/data/location_model.dart';
import 'package:mobile/features/location/data/location_service.dart';
import 'package:mobile/features/location/data/location_update_service.dart';

class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider(this.location);

  final AcquiredLocation location;

  @override
  Future<AcquiredLocation> getCurrentLocation() async => location;
}

class FakeLocationService extends LocationService {
  FakeLocationService(this.result) : super(apiClient: null, tokenStorage: null);

  final LocationModel result;
  double? receivedLatitude;
  double? receivedLongitude;
  double? receivedAccuracy;
  DateTime? receivedCapturedAt;

  @override
  Future<LocationModel> updateMyLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required DateTime capturedAt,
  }) async {
    receivedLatitude = latitude;
    receivedLongitude = longitude;
    receivedAccuracy = accuracyMeters;
    receivedCapturedAt = capturedAt;
    return result;
  }
}

void main() {
  test(
    'acquisition is forwarded to the existing API location service',
    () async {
      final capturedAt = DateTime.parse('2026-08-09T08:00:00.000Z');
      final apiResult = LocationModel(
        id: 'location-123',
        latitude: 28.7041,
        longitude: 77.1025,
        accuracyMeters: 25,
        capturedAt: capturedAt,
        createdAt: capturedAt,
        updatedAt: capturedAt,
        locality: const LocalityModel(
          id: 'development-locality-a',
          name: 'Test Locality A',
          city: 'Delhi',
          state: 'Delhi',
          country: 'India',
        ),
      );
      final locationService = FakeLocationService(apiResult);
      final updateService = LocationUpdateService(
        locationProvider: FakeLocationProvider(
          AcquiredLocation(
            latitude: 28.7041,
            longitude: 77.1025,
            accuracyMeters: 25,
            capturedAt: capturedAt,
          ),
        ),
        locationService: locationService,
      );

      final result = await updateService.updateCurrentLocation();

      expect(result, apiResult);
      expect(locationService.receivedLatitude, 28.7041);
      expect(locationService.receivedLongitude, 77.1025);
      expect(locationService.receivedAccuracy, 25);
      expect(locationService.receivedCapturedAt, capturedAt);
    },
  );
}
