import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/public_user_model.dart';
import '../data/public_user_service.dart';

class PublicAuthorProfileScreen extends StatefulWidget {
  const PublicAuthorProfileScreen({
    super.key,
    required this.userId,
    this.publicUserService,
    this.onSessionExpired,
  });

  final String userId;
  final PublicUserService? publicUserService;
  final VoidCallback? onSessionExpired;

  @override
  State<PublicAuthorProfileScreen> createState() =>
      _PublicAuthorProfileScreenState();
}

class _PublicAuthorProfileScreenState extends State<PublicAuthorProfileScreen> {
  PublicUserModel? _user;
  String? _errorMessage;
  bool _isLoading = true;

  PublicUserService get _service =>
      widget.publicUserService ?? PublicUserService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _service.getPublicUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isLoading = false;
        _errorMessage = error.statusCode == 404
            ? 'User not found.'
            : 'Couldn\'t load profile.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Couldn\'t load profile.';
      });
    }
  }

  String _displayName(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Khabro User' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public Profile')),
      body: _isLoading
          ? const Center(child: Text('Loading profile...'))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    if (_errorMessage != 'User not found.') ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadProfile,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName(_user!.name),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
