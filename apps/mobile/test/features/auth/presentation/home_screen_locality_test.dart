import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';
import 'package:mobile/features/location/data/locality_model.dart';
import 'package:mobile/features/location/data/locality_service.dart';

class FakeLocalityService extends LocalityService {
  FakeLocalityService(this.result, {this.error})
    : super(apiClient: null, tokenStorage: null);

  final LocalityModel? result;
  final AuthException? error;

  @override
  Future<LocalityModel?> getMyLocality() async {
    if (error != null) throw error!;
    return result;
  }
}

const testUser = UserModel(
  id: 'user-123',
  phone: '+919876543210',
  name: 'Test User',
  trustScore: 0,
  status: 'ACTIVE',
);

void main() {
  testWidgets('shows locality fields without coordinates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: testUser,
          onLogout: () {},
          localityService: FakeLocalityService(
            const LocalityModel(
              id: 'development-locality-a',
              name: 'Test Locality A',
              city: 'Delhi',
              state: 'Delhi',
              country: 'India',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SHOW MY LOCALITY'));
    await tester.pumpAndSettle();

    expect(find.text('Your Local Area'), findsOneWidget);
    expect(find.text('Test Locality A'), findsOneWidget);
    expect(find.text('Delhi'), findsNWidgets(2));
    expect(find.text('India'), findsOneWidget);
    expect(find.text('28.7041'), findsNothing);
    expect(find.text('77.1025'), findsNothing);
    expect(find.byIcon(Icons.map), findsNothing);
    expect(find.byIcon(Icons.place), findsNothing);
  });

  testWidgets('shows a friendly locality error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: testUser,
          onLogout: () {},
          localityService: FakeLocalityService(
            null,
            error: const AuthException('Locality unavailable', statusCode: 500),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SHOW MY LOCALITY'));
    await tester.pumpAndSettle();

    expect(find.text('Locality unavailable'), findsOneWidget);
  });
}
