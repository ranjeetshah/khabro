import 'package:flutter/material.dart';
import '../../auth/data/auth_exception.dart';
import '../data/account_suggestion_model.dart';
import '../data/users_service.dart';
import 'public_author_profile_screen.dart';
import '../data/public_user_service.dart';

class AccountSuggestionsScreen extends StatefulWidget {
  const AccountSuggestionsScreen({
    super.key,
    this.usersService,
    this.publicUserService,
    this.currentUserId,
    this.onSessionExpired,
  });

  final UsersService? usersService;
  final PublicUserService? publicUserService;
  final String? currentUserId;
  final VoidCallback? onSessionExpired;

  @override
  State<AccountSuggestionsScreen> createState() =>
      _AccountSuggestionsScreenState();
}

class _AccountSuggestionsScreenState extends State<AccountSuggestionsScreen> {
  late final UsersService _usersService;
  final List<AccountSuggestionModel> _suggestions = [];
  final Set<String> _followedIds = {};
  final Set<String> _loadingIds = {};

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
      _suggestions.clear();
      _followedIds.clear();
      _loadingIds.clear();
      _hasMore = true;
    });

    try {
      final list = await _usersService.getAccountSuggestions(
        page: 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _suggestions.addAll(list);
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
        _errorMessage = "Couldn't load suggestions.";
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
      final list = await _usersService.getAccountSuggestions(
        page: nextPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _suggestions.addAll(list);
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

  Future<void> _followUser(String userId) async {
    if (_loadingIds.contains(userId) || _followedIds.contains(userId)) return;

    setState(() {
      _loadingIds.add(userId);
    });

    try {
      await _usersService.followUser(userId);
      if (!mounted) return;
      setState(() {
        _loadingIds.remove(userId);
        _followedIds.add(userId);
      });

      // Brief delay for transition feedback before removing card
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _suggestions.removeWhere((item) => item.id == userId);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() {
        _loadingIds.remove(userId);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to follow. Please try again.')),
      );
      setState(() {
        _loadingIds.remove(userId);
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
        title: const Text('People you may know'),
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

    if (_suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "You're all caught up.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "We'll show new people here when we find relevant connections.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
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
          itemCount: _suggestions.length + (_hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == _suggestions.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final item = _suggestions[index];
            final isFollowing = _followedIds.contains(item.id);
            final isBtnLoading = _loadingIds.contains(item.id);

            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withAlpha(10),
                  child: Text(
                    _displayName(item.name)[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _displayName(item.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.reason!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${item.followerCount} followers',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 96,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isBtnLoading || isFollowing
                        ? null
                        : () => _followUser(item.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.white
                          : const Color(0xFF1565C0),
                      foregroundColor: isFollowing
                          ? const Color(0xFF374151)
                          : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isFollowing
                            ? const BorderSide(color: Color(0xFFD1D5DB))
                            : BorderSide.none,
                      ),
                    ),
                    child: isBtnLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.grey),
                            ),
                          )
                        : Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicAuthorProfileScreen(
                        userId: item.id,
                        currentUserId: widget.currentUserId,
                        usersService: _usersService,
                        publicUserService: widget.publicUserService,
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
