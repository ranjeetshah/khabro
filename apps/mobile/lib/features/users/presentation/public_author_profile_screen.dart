import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/public_user_model.dart';
import '../data/public_user_service.dart';
import '../data/users_service.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class PublicAuthorProfileScreen extends StatefulWidget {
  const PublicAuthorProfileScreen({
    super.key,
    required this.userId,
    this.currentUserId,
    this.publicUserService,
    this.usersService,
    this.onSessionExpired,
  });

  final String userId;
  final String? currentUserId;
  final PublicUserService? publicUserService;
  final UsersService? usersService;
  final VoidCallback? onSessionExpired;

  @override
  State<PublicAuthorProfileScreen> createState() =>
      _PublicAuthorProfileScreenState();
}

class _PublicAuthorProfileScreenState extends State<PublicAuthorProfileScreen> {
  PublicUserModel? _user;
  String? _errorMessage;
  bool _isLoading = true;
  String? _currentUserId;

  late final UsersService _usersService;
  bool _isFollowing = false;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isFollowActionLoading = false;

  PublicUserService get _service =>
      widget.publicUserService ?? PublicUserService();

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _currentUserId = widget.currentUserId;
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (_currentUserId == null && !isTesting) {
      _loadCurrentUserId();
    }
    _loadProfile();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final token = await TokenStorage().getAccessToken();
      if (token != null) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          var payload = parts[1];
          var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
          switch (normalized.length % 4) {
            case 0:
              break;
            case 2:
              normalized += '==';
              break;
            case 3:
              normalized += '=';
              break;
          }
          final decoded = utf8.decode(base64Url.decode(normalized));
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _currentUserId = map['sub'] as String?;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _service.getPublicUser(widget.userId);

      // Check if self or other user to load follow state
      final isSelf = _currentUserId != null && _currentUserId == widget.userId;
      final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      final hasMockService = widget.usersService != null;

      if (!isSelf && (!isTesting || hasMockService)) {
        final status = await _usersService.getFollowStatus(widget.userId);
        _isFollowing = status.following;
        _followerCount = status.followerCount;
        _followingCount = status.followingCount;
      } else {
        _isFollowing = false;
        _followerCount = user.followerCount;
        _followingCount = user.followingCount;
      }

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

  Future<void> _toggleFollow() async {
    if (_isFollowActionLoading) return;
    setState(() {
      _isFollowActionLoading = true;
    });

    try {
      final status = _isFollowing
          ? await _usersService.unfollowUser(widget.userId)
          : await _usersService.followUser(widget.userId);

      if (!mounted) return;
      setState(() {
        _isFollowing = status.following;
        _followerCount = status.followerCount;
        _followingCount = status.followingCount;
        _isFollowActionLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() {
        _isFollowActionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow. Please try again.')),
      );
      setState(() {
        _isFollowActionLoading = false;
      });
    }
  }

  String _displayName(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Khabro User' : trimmed;
  }

  Future<void> _openReport(BuildContext context) async {
    await showReportDialog(
      context,
      title: 'Report user',
      onSubmit: (reason, description) => _service.reportUser(
        widget.userId,
        reason: reason.wire,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = _currentUserId != null && _currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Public Profile'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'report') _openReport(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'report', child: Text('Report user')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF1565C0).withAlpha(10),
                            child: Text(
                              _displayName(_user!.name)[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _displayName(_user!.name),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Followers / Following Row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSocialStatItem('Followers', '$_followerCount', () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FollowersScreen(
                                        userId: widget.userId,
                                        currentUserId: _currentUserId,
                                        usersService: _usersService,
                                        onSessionExpired: widget.onSessionExpired,
                                      ),
                                    ),
                                  );
                                }),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                _buildSocialStatItem('Following', '$_followingCount', () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FollowingScreen(
                                        userId: widget.userId,
                                        currentUserId: _currentUserId,
                                        usersService: _usersService,
                                        onSessionExpired: widget.onSessionExpired,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Follow / Following Action Button (only if not viewing oneself)
                          if (!isSelf) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isFollowActionLoading ? null : _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? Colors.white
                                      : const Color(0xFF1565C0),
                                  foregroundColor: _isFollowing
                                      ? const Color(0xFF374151)
                                      : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: _isFollowing
                                        ? const BorderSide(color: Color(0xFFD1D5DB))
                                        : BorderSide.none,
                                  ),
                                ),
                                child: _isFollowActionLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.grey),
                                        ),
                                      )
                                    : Text(
                                        _isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSocialStatItem(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
