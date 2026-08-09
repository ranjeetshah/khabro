import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../auth/data/models/user_model.dart';
import '../data/users_service.dart';

/// Profile screen for viewing and editing the authenticated user's profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    this.usersService,
    this.onUserUpdated,
    this.onSessionExpired,
  });

  final UserModel user;
  final UsersService? usersService;
  final ValueChanged<UserModel>? onUserUpdated;
  final VoidCallback? onSessionExpired;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UsersService _usersService;
  late UserModel _user;
  late TextEditingController _nameController;

  bool _isEditing = false;
  bool _isSaving = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _user = widget.user;
    _nameController = TextEditingController(text: _user.name ?? '');
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _usersService.getMe();
      setState(() {
        _user = user;
        _nameController.text = user.name ?? '';
        _message = '';
      });
      widget.onUserUpdated?.call(user);
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        widget.onSessionExpired?.call();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _message = e.message;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to load profile.';
      });
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      setState(() {
        _message = 'Name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _message = '';
    });

    try {
      final updatedUser = await _usersService.updateMe(newName);
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _message = 'Name updated successfully!';
      });
      widget.onUserUpdated?.call(updatedUser);
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        widget.onSessionExpired?.call();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _message = 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to update profile.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = _user.name ?? '';
      _message = '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSaving ? null : _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.person, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Khabro',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadOnlyRow('Phone', _user.phone),
                        const Divider(height: 24),

                        // Name — editable
                        if (_isEditing) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 100,
                            enabled: !_isSaving,
                          ),
                        ] else ...[
                          _buildReadOnlyRow('Name', _user.name ?? '—'),
                        ],

                        const Divider(height: 24),
                        _buildReadOnlyRow('Trust Score', '${_user.trustScore}'),
                        const SizedBox(height: 8),
                        _buildReadOnlyRow('Status', _user.status),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                if (_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveName,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('SAVE'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEditing,
                      child: const Text('CANCEL'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _message = '';
                        });
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('EDIT NAME'),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Message display
                if (_message.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _message.startsWith('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message.startsWith('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
