import 'package:flutter/material.dart';

import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/auth_gate.dart';

void main() {
  runApp(const KhabroApp());
}

class KhabroApp extends StatelessWidget {
  const KhabroApp({
    super.key,
    this.authService,
    this.tokenStorage,
  });

  final AuthService? authService;
  final TokenStorage? tokenStorage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khabro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        authService: authService,
        tokenStorage: tokenStorage,
      ),
    );
  }
}