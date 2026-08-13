import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../auth/data/models/user_model.dart';
import '../data/profile_model.dart';
import '../data/users_service.dart';
import 'my_posts_screen.dart';
import 'my_reports_screen.dart';
import 'witness_history_screen.dart';

/// Profile screen for viewing and editing the authenticated user's profile and contributions.
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
  ProfileModel? _profile;
  late TextEditingController _nameController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _user = widget.user;
    _nameController = TextEditingController(text: _user.name ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      final profile = await _usersService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _user = UserModel(
          id: profile.id,
          phone: profile.phone,
          name: profile.name,
          trustScore: _user.trustScore,
          status: _user.status,
          createdAt: profile.createdAt,
          updatedAt: profile.createdAt,
        );
        _nameController.text = profile.name ?? '';
        _isLoading = false;
      });
      widget.onUserUpdated?.call(_user);
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        widget.onSessionExpired?.call();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (!mounted) return;
      setState(() {
        _message = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to load profile.';
        _isLoading = false;
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
      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _message = 'Name updated successfully!';
      });
      widget.onUserUpdated?.call(updatedUser);
      _loadProfile();
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        widget.onSessionExpired?.call();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (!mounted) return;
      setState(() {
        _message = 'Error: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (_user.name != null && _user.name!.isNotEmpty)
                              ? _user.name![0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user.name ?? 'Khabro Citizen',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${_formatDate(_profile?.createdAt ?? _user.createdAt ?? DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Community Contributions Card
                      _buildContributionsCard(),
                      const SizedBox(height: 20),

                      // Navigation Actions
                      _buildNavigationCard(),
                      const SizedBox(height: 20),

                      // User Info Card
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

  Widget _buildContributionsCard() {
    final stats = _profile?.stats ??
        const ProfileStatsModel(
          postCount: 0,
          reportCount: 0,
          witnessCount: 0,
          verifiedContributionCount: 0,
        );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Contributions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Posts', '${stats.postCount}'),
                _buildStatItem('Reports', '${stats.reportCount}'),
                _buildStatItem('Witnessed', '${stats.witnessCount}'),
                _buildStatItem('Verified', '${stats.verifiedContributionCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNavigationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined, color: Colors.blue),
            title: const Text('My Posts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyPostsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.report_outlined, color: Colors.orange),
            title: const Text('My Reports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MyReportsScreen(usersService: _usersService),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: Colors.green),
            title: const Text('Witness History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      WitnessHistoryScreen(usersService: _usersService),
                ),
              );
            },
          ),
        ],
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

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
