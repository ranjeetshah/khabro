import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('KhabroApp smoke test — renders login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KhabroApp());

    // Verify the app title and login UI are present.
    expect(find.text('Khabro'), findsWidgets);
    expect(find.text('DEV LOGIN'), findsOneWidget);
    expect(find.text('REGISTER TEST USER'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
