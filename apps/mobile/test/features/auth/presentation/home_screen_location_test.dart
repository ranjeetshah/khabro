import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';
import 'package:mobile/features/location/data/location_model.dart';
import 'package:mobile/features/location/data/location_update_service.dart';

class FakeLocationUpdateService extends LocationUpdateService {
  FakeLocationUpdateService(this.result)
    : super(locationProvider: null, locationService: null);

  final LocationModel result;

  @override
  Future<LocationModel> updateCurrentLocation() async => result;
}

const testUser = UserModel(
  id: 'user-123',
  phone: '+919876543210',
  name: 'Test User',
  trustScore: 0,
  status: 'ACTIVE',
);

void main() {
  testWidgets('explicit location action shows generic success', (tester) async {
    final now = DateTime.parse('2026-08-09T08:00:00.000Z');
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: testUser,
          onLogout: () {},
          locationUpdateService: FakeLocationUpdateService(
            LocationModel(
              id: 'location-123',
              latitude: 28.7041,
              longitude: 77.1025,
              accuracyMeters: 25,
              capturedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('UPDATE MY LOCATION'));
    await tester.pumpAndSettle();

    expect(find.text('Location updated successfully'), findsOneWidget);
    expect(find.text('28.7041'), findsNothing);
    expect(find.text('77.1025'), findsNothing);
  });
}
