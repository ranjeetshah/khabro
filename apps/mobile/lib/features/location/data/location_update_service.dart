import 'location_acquisition.dart';
import 'location_model.dart';
import 'location_service.dart';

/// Coordinates explicit device acquisition with the existing API service.
class LocationUpdateService {
  LocationUpdateService({
    LocationProvider? locationProvider,
    LocationService? locationService,
  }) : _locationProvider = locationProvider ?? GeolocatorLocationProvider(),
       _locationService = locationService ?? LocationService();

  final LocationProvider _locationProvider;
  final LocationService _locationService;

  Future<LocationModel> updateCurrentLocation() async {
    final acquired = await _locationProvider.getCurrentLocation();

    return _locationService.updateMyLocation(
      latitude: acquired.latitude,
      longitude: acquired.longitude,
      accuracyMeters: acquired.accuracyMeters,
      capturedAt: acquired.capturedAt,
    );
  }
}
