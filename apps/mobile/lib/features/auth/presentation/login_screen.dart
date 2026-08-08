import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/auth_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController =
      TextEditingController(text: '9999999999');

  final AuthService _authService = AuthService();

  bool loading = false;
  String message = '';

  // ------------------------------------------------------------
  // REGISTER TEST USER
  // ------------------------------------------------------------

  Future<void> register() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final response = await _authService.register(
        phoneController.text.trim(),
        'Test User',
      );

      setState(() {
        message =
            'Registration Successful!\n\n'
            'User:\n'
            '${const JsonEncoder.withIndent('  ').convert(response.user.toJson())}';
      });

      await _fetchMe();
    } on AuthException catch (e) {
      setState(() {
        message = 'Error (${e.statusCode ?? 'unknown'}): ${e.message}';
      });
    } catch (e) {
      setState(() {
        message = 'Connection error. Is the backend running?';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // DEV LOGIN
  // ------------------------------------------------------------

  Future<void> login() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await _authService.devLogin(phoneController.text.trim());

      setState(() {
        message = 'JWT Login Successful!\n\nChecking /auth/me...';
      });

      await _fetchMe();
    } on AuthException catch (e) {
      setState(() {
        message = 'Error (${e.statusCode ?? 'unknown'}): ${e.message}';
      });
    } catch (e) {
      setState(() {
        message = 'Connection error. Is the backend running?';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // GET CURRENT USER
  // ------------------------------------------------------------

  Future<void> _fetchMe() async {
    try {
      final user = await _authService.getMe();

      setState(() {
        message =
            'Authenticated!\n\n'
            'User:\n'
            '${const JsonEncoder.withIndent('  ').convert(user.toJson())}';
      });
    } on AuthException catch (e) {
      setState(() {
        message = 'Auth check failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        message = 'Failed to verify authentication.';
      });
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khabro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_city,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Khabro',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Local. Verified. Connected.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // DEV LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('DEV LOGIN'),
                  ),
                ),

                const SizedBox(height: 10),

                // REGISTER
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: loading ? null : register,
                    child: const Text(
                      'REGISTER TEST USER',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // RESPONSE
                if (message.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      message,
                      textAlign: TextAlign.left,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
