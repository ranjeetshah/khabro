import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../auth/data/models/user_model.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/posts_service.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../data/profile_model.dart';
import '../data/users_service.dart';
import 'my_posts_screen.dart';
import 'my_reports_screen.dart';
import 'witness_history_screen.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../../feedback/data/feedback_service.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'account_suggestions_screen.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/presentation/conversations_screen.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../moderator/data/moderator_service.dart';
import '../../moderator/presentation/moderator_dashboard_screen.dart';

/// Profile screen for viewing and editing the authenticated user's profile and contributions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    this.usersService,
    this.postsService,
    this.apiClient,
    this.tokenStorage,
    this.chatService,
    this.onUserUpdated,
    this.onSessionExpired,
  });

  final UserModel user;
  final UsersService? usersService;
  final PostsService? postsService;
  final ApiClient? apiClient;
  final TokenStorage? tokenStorage;
  final ChatService? chatService;
  final ValueChanged<UserModel>? onUserUpdated;
  final VoidCallback? onSessionExpired;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UsersService _usersService;
  late final ChatService _chatService;
  late UserModel _user;
  ProfileModel? _profile;
  late TextEditingController _nameController;

  int _unreadChatCount = 0;

  List<PostModel> _userPosts = [];
  bool _isPostsLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _chatService = widget.chatService ?? ChatService();
    _user = widget.user;
    _nameController = TextEditingController(text: _user.name ?? '');
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.usersService != null || !isTesting) {
      _loadProfile();
    } else {
      _isLoading = false;
    }
    if (widget.chatService != null || !isTesting) {
      _loadUnreadChatCount();
    }
  }

  Future<void> _loadUnreadChatCount() async {
    try {
      final count = await _chatService.getUnreadCount();
      if (!mounted) return;
      setState(() {
        _unreadChatCount = count;
      });
    } on AuthException catch (e) {
      if (e.statusCode == 401) widget.onSessionExpired?.call();
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _isPostsLoading = true;
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
          role: _user.role,
          createdAt: profile.createdAt,
          updatedAt: profile.createdAt,
        );
        _nameController.text = profile.name ?? '';
        _isLoading = false;
      });
      widget.onUserUpdated?.call(_user);

      if (widget.postsService != null) {
        final posts = await widget.postsService!.getMyPosts();
        if (!mounted) return;
        setState(() {
          _userPosts = posts;
          _isPostsLoading = false;
        });
      } else {
        setState(() {
          _isPostsLoading = false;
        });
      }
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
        _isPostsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to load profile.';
        _isLoading = false;
        _isPostsLoading = false;
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

  int _selectedTab = 0;

  Widget _buildCircularHighlights() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildHighlightItem(
              icon: Icons.article_outlined,
              label: 'My Posts',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyPostsScreen(postsService: widget.postsService),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            _buildHighlightItem(
              icon: Icons.visibility_outlined,
              label: 'Witness History',
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WitnessHistoryScreen(usersService: _usersService),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            _buildHighlightItem(
              icon: Icons.feedback_outlined,
              label: 'Feedback',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(
                      feedbackService: FeedbackService(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            _buildHighlightItem(
              icon: Icons.report_outlined,
              label: 'My Reports',
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyReportsScreen(usersService: _usersService),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(30), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Updates'),
          _buildTabItem(1, 'Contributions'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      if (_isPostsLoading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (_userPosts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.article_outlined, size: 48, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'No posts yet',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
              ),
              SizedBox(height: 4),
              Text(
                'Share your first civic update.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        );
      }
      return Column(
        children: _userPosts.map((post) {
          return Card(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              title: Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              subtitle: Text(
                'Posted ${_formatDate(post.createdAt)} • ${post.verificationStatus.wire}',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(
                      post: post,
                      postsService: widget.postsService ?? PostsService(),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      );
    } else {
      // Tab 1: Contributions
      return Column(
        children: [
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyRow('Phone', _user.phone),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  if (_isEditing) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      maxLength: 100,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveName,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : const Text('SAVE'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _cancelEditing,
                            child: const Text('CANCEL'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildReadOnlyRow('Name', _user.name ?? '—'),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),
                    _buildReadOnlyRow('Status', _user.status),
                  ],
                ],
              ),
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _message = '';
                  });
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('EDIT NAME', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_user.role?.toUpperCase() == 'MODERATOR') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModeratorDashboardScreen(
                          moderatorService: ModeratorService(
                            apiClient: widget.apiClient,
                            tokenStorage: widget.tokenStorage,
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('MODERATOR CONSOLE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                        backgroundColor: const Color(0xFF1565C0).withAlpha(20),
                        child: Text(
                          (_user.name != null && _user.name!.isNotEmpty)
                              ? _user.name![0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user.name ?? 'Khabro Citizen',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${_formatDate(_profile?.createdAt ?? _user.createdAt ?? DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Social Stats Card
                      _buildSocialStatsRow(),
                      const SizedBox(height: 20),

                      // Messages Entry Card
                      _buildMessagesEntryCard(),
                      const SizedBox(height: 20),

                      // People You May Know Discovery Card
                      _buildSuggestionsEntryCard(),
                      const SizedBox(height: 20),

                      // Community Contributions Card
                      _buildContributionsCard(),
                      const SizedBox(height: 20),

                      // Circular Highlights/Shortcuts
                      _buildCircularHighlights(),
                      const SizedBox(height: 20),

                      // Tabs & Tab Content
                      _buildTabBar(),
                      _buildTabContent(),

                      const SizedBox(height: 16),

                      // Message display
                      if (_message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _message.startsWith('Error') ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                            border: Border.all(
                              color: _message.startsWith('Error')
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _message.startsWith('Error')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
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

  Widget _buildContributionsCard() {
    final stats = _profile?.stats ??
        const ProfileStatsModel(
          postCount: 0,
          reportCount: 0,
          witnessCount: 0,
          verifiedContributionCount: 0,
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Contributions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
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
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  Widget _buildSocialStatsRow() {
    final stats = _profile?.stats;
    final postCount = stats?.postCount ?? 0;
    final followerCount = stats?.followerCount ?? 0;
    final followingCount = stats?.followingCount ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialStatItem('Posts', '$postCount', null),
          _buildVerticalDivider(),
          _buildSocialStatItem('Followers', '$followerCount', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FollowersScreen(
                  userId: _user.id,
                  currentUserId: _user.id,
                  usersService: _usersService,
                  onSessionExpired: widget.onSessionExpired,
                ),
              ),
            );
          }),
          _buildVerticalDivider(),
          _buildSocialStatItem('Following', '$followingCount', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FollowingScreen(
                  userId: _user.id,
                  currentUserId: _user.id,
                  usersService: _usersService,
                  onSessionExpired: widget.onSessionExpired,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSocialStatItem(String label, String value, VoidCallback? onTap) {
    final content = Column(
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
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: content,
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildMessagesEntryCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Color(0xFF1565C0),
          ),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: const Text(
          'Chat 1-on-1 with citizens in your community',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_unreadChatCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadChatCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationsScreen(
                chatService: widget.chatService,
                onSessionExpired: widget.onSessionExpired,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsEntryCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline,
            color: Color(0xFF1565C0),
          ),
        ),
        title: const Text(
          'People you may know',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: const Text(
          'Discover active citizens in your community',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF9CA3AF),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountSuggestionsScreen(
                usersService: _usersService,
                currentUserId: _user.id,
                onSessionExpired: widget.onSessionExpired,
              ),
            ),
          );
        },
      ),
    );
  }
}
