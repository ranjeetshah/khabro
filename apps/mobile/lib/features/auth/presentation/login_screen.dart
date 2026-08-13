import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/auth_exception.dart';
import '../data/auth_service.dart';
import '../data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService,
    this.onAuthenticated,
  });

  final AuthService? authService;
  final ValueChanged<UserModel>? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController =
      TextEditingController(text: '9999999999');

  late final AuthService _authService;

  bool loading = false;
  bool _showDevOptions = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _showDevOptions = WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

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

      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(response.user);
        return;
      }

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
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
      final response = await _authService.devLogin(phoneController.text.trim());

      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(response.user);
        return;
      }

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
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // GET CURRENT USER
  // ------------------------------------------------------------

  Future<void> _fetchMe() async {
    try {
      final user = await _authService.getMe();

      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(user);
        return;
      }

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Khabro',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your city. Your voice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    key: const Key('loginPhoneField'),
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: 'Enter your 10-digit number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('loginContinueButton'),
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDevOptions = !_showDevOptions;
                        });
                      },
                      icon: Icon(
                        _showDevOptions
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF6B7280),
                      ),
                      label: const Text(
                        'Developer Options',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_showDevOptions) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          key: const Key('loginDevButton'),
                          onPressed: loading ? null : login,
                          child: const Text(
                            'DEV LOGIN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          key: const Key('loginRegisterButton'),
                          onPressed: loading ? null : register,
                          child: const Text(
                            'REGISTER TEST USER',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: SelectableText(
                        message,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
