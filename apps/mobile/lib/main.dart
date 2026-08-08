import 'package:flutter/material.dart';

import 'features/auth/presentation/login_screen.dart';

void main() {
  runApp(const KhabroApp());
}

class KhabroApp extends StatelessWidget {
  const KhabroApp({super.key});

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
      home: const LoginScreen(),
    );
  }
}