import 'package:flutter/material.dart';
import '../../auth/data/auth_exception.dart';
import '../data/public_user_model.dart';
import '../data/users_service.dart';
import 'public_author_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({
    super.key,
    required this.userId,
    this.usersService,
    this.currentUserId,
    this.onSessionExpired,
  });

  final String userId;
  final UsersService? usersService;
  final String? currentUserId;
  final VoidCallback? onSessionExpired;

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  late final UsersService _usersService;
  final List<PublicUserModel> _followers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _followers.clear();
      _hasMore = true;
    });

    try {
      final list = await _usersService.getFollowers(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _followers.addAll(list);
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load followers. Please try again.";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final list = await _usersService.getFollowers(
        userId: widget.userId,
        page: nextPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _followers.addAll(list);
        _currentPage = nextPage;
        _hasMore = list.length >= 20;
        _isLoadingMore = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Followers'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadInitial,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Text(
          'No followers yet.',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore &&
              _hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _followers.length + (_hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == _followers.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final user = _followers[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withAlpha(10),
                  child: Text(
                    _displayName(user.name)[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _displayName(user.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicAuthorProfileScreen(
                        userId: user.id,
                        currentUserId: widget.currentUserId,
                        onSessionExpired: widget.onSessionExpired,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
