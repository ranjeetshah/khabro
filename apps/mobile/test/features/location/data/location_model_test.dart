import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/data/location_model.dart';

const validLocationJson = {
  'id': 'location-123',
  'latitude': 28.7041,
  'longitude': 77.1025,
  'accuracyMeters': 25,
  'capturedAt': '2026-08-09T08:00:00.000Z',
  'createdAt': '2026-08-09T08:00:01.000Z',
  'updatedAt': '2026-08-09T08:00:02.000Z',
};

void main() {
  group('LocationModel', () {
    test('parses valid JSON', () {
      final location = LocationModel.fromJson(validLocationJson);

      expect(location.id, 'location-123');
      expect(location.latitude, 28.7041);
      expect(location.longitude, 77.1025);
      expect(location.accuracyMeters, 25);
      expect(location.capturedAt, DateTime.parse('2026-08-09T08:00:00.000Z'));
    });

    test('accepts nullable accuracy', () {
      final location = LocationModel.fromJson({
        ...validLocationJson,
        'accuracyMeters': null,
      });

      expect(location.accuracyMeters, isNull);
    });

    test('serializes safe fields without coordinates', () {
      final location = LocationModel.fromJson(validLocationJson);

      expect(location.toJson(), {
        'id': 'location-123',
        'capturedAt': '2026-08-09T08:00:00.000Z',
        'createdAt': '2026-08-09T08:00:01.000Z',
        'updatedAt': '2026-08-09T08:00:02.000Z',
      });
      expect(location.toJson().containsKey('latitude'), isFalse);
      expect(location.toJson().containsKey('longitude'), isFalse);
      expect(location.toJson().containsKey('accuracyMeters'), isFalse);
    });

    test('parses a stored locality without coordinates', () {
      final location = LocationModel.fromJson({
        'id': 'location-123',
        'capturedAt': '2026-08-09T08:00:00.000Z',
        'createdAt': '2026-08-09T08:00:01.000Z',
        'updatedAt': '2026-08-09T08:00:02.000Z',
        'locality': {
          'id': 'development-locality-a',
          'name': 'Test Locality A',
          'city': 'Delhi',
          'state': 'Delhi',
          'country': 'India',
        },
      });

      expect(location.latitude, isNull);
      expect(location.locality?.name, 'Test Locality A');
    });

    test('throws when required fields are missing', () {
      expect(
        () => LocationModel.fromJson({'id': 'location-123'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('throws for an invalid timestamp', () {
      expect(
        () => LocationModel.fromJson({
          ...validLocationJson,
          'capturedAt': 'invalid',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
