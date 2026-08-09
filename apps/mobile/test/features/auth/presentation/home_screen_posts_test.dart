import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';

const testUser = UserModel(
  id: 'user-1',
  phone: '+919876543210',
  name: 'Test User',
  trustScore: 0,
  status: 'ACTIVE',
);

void main() {
  testWidgets('does not render the obsolete test posts section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(user: testUser, onLogout: () {})),
    );

    expect(find.text('Test Posts'), findsNothing);
    expect(find.text('Post text'), findsNothing);
    expect(find.text('CREATE TEST POST'), findsNothing);
    expect(find.text('LOAD MY POSTS'), findsNothing);
    expect(find.text('OPEN LOCAL FEED'), findsOneWidget);
  });
}
