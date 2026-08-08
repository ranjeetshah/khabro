import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/main.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this._token]) : super(storage: null);

  String? _token;

  @override
  Future<void> saveAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _token;
  }

  @override
  Future<void> deleteAccessToken() async {
    _token = null;
  }
}

void main() {
  testWidgets('KhabroApp smoke test — renders login screen when no token',
      (WidgetTester tester) async {
    final tokenStorage = FakeTokenStorage();

    await tester.pumpWidget(KhabroApp(tokenStorage: tokenStorage));
    await tester.pumpAndSettle();

    // Verify the app title and login UI are present.
    expect(find.text('Khabro'), findsWidgets);
    expect(find.text('DEV LOGIN'), findsOneWidget);
    expect(find.text('REGISTER TEST USER'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
