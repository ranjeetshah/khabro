import 'package:flutter/material.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_exception.dart';
import '../data/auth_service.dart';
import '../data/models/user_model.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Manages authentication session state on app startup and handles transitions
/// between LoginScreen and HomeScreen based on stored token validity.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authService,
    this.tokenStorage,
  });

  final AuthService? authService;
  final TokenStorage? tokenStorage;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final TokenStorage _tokenStorage;

  bool _isLoading = true;
  UserModel? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenStorage = widget.tokenStorage ?? TokenStorage();
    _authService =
        widget.authService ?? AuthService(tokenStorage: _tokenStorage);
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _user = null;
        });
        return;
      }

      final user = await _authService.getMe();
      setState(() {
        _isLoading = false;
        _user = user;
      });
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        await _tokenStorage.deleteAccessToken();
        setState(() {
          _isLoading = false;
          _user = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Session restoration failed. Please check your connection.';
      });
    }
  }

  Future<void> _logout() async {
    await _tokenStorage.deleteAccessToken();
    setState(() {
      _user = null;
      _errorMessage = null;
    });
  }

  void _onAuthenticated(UserModel user) {
    setState(() {
      _user = user;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Khabro')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkSession,
                  child: const Text('RETRY'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _logout,
                  child: const Text('BACK TO LOGIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_user != null) {
      return HomeScreen(
        user: _user!,
        onLogout: _logout,
      );
    }

    return LoginScreen(
      authService: _authService,
      onAuthenticated: _onAuthenticated,
    );
  }
}
