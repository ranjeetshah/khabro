import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../location/data/locality_service.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/posts_service.dart';
import '../../posts/presentation/create_post_screen.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../posts/presentation/verification_status_badge.dart';
import '../../users/data/public_user_service.dart';
import '../data/feed_page_model.dart';
import '../data/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    this.feedService,
    this.postsService,
    this.localityService,
    this.onUpdateLocation,
    this.onSessionExpired,
    this.publicUserService,
    this.currentUserId,
  });

  final FeedService? feedService;
  final PostsService? postsService;
  final LocalityService? localityService;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onSessionExpired;
  final PublicUserService? publicUserService;
  final String? currentUserId;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<PostModel> _items = const [];
  String? _nextCursor;
  String? _errorMessage;
  bool _hasLocality = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final Set<String> _likeRequests = <String>{};
  String? _likeError;
  final Set<String> _witnessRequests = <String>{};
  String? _witnessError;
  String? _witnessRetryPostId;

  FeedService get _service => widget.feedService ?? FeedService();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial({bool refreshing = false}) async {
    if (!refreshing) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      if (widget.localityService != null) {
        final locality = await widget.localityService!.getMyLocality();
        if (locality == null) {
          if (!mounted) return;
          setState(() {
            _hasLocality = false;
            _items = const [];
            _nextCursor = null;
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }
      }
      _hasLocality = true;
      final page = await _service.getFeed();
      if (!mounted) return;
      _applyPage(page, append: false);
    } on AuthException catch (error) {
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      _showError(error.message);
    } catch (_) {
      _showError('Could not load your local feed. Please try again.');
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });
    try {
      final page = await _service.getFeed(cursor: _nextCursor);
      if (!mounted) return;
      _applyPage(page, append: true);
    } on AuthException catch (error) {
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      _showError(error.message, loadingMore: true);
    } catch (_) {
      _showError(
        'Could not load more posts. Please try again.',
        loadingMore: true,
      );
    }
  }

  void _applyPage(FeedPageModel page, {required bool append}) {
    final existingIds = _items.map((item) => item.id).toSet();
    final pageIds = <String>{};
    final uniquePageItems = page.items
        .where((item) => pageIds.add(item.id))
        .toList();
    final newItems = append
        ? uniquePageItems
              .where((item) => !existingIds.contains(item.id))
              .toList()
        : uniquePageItems;
    setState(() {
      _items = append ? [..._items, ...newItems] : newItems;
      _nextCursor = page.nextCursor;
      _errorMessage = null;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _showError(String message, {bool loadingMore = false}) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isLoadingMore = loadingMore ? false : _isLoadingMore;
    });
  }

  Future<void> _openComposer() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreatePostScreen(
          postsService: widget.postsService,
          onPostCreated: () => _loadInitial(refreshing: true),
        ),
      ),
    );
  }

  Future<void> _openPost(PostModel post) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostDetailScreen(
          post: post,
          postsService: widget.postsService,
          publicUserService: widget.publicUserService,
          currentUserId: widget.currentUserId,
          onSessionExpired: widget.onSessionExpired,
        ),
      ),
    );
    if (deleted == true && mounted) {
      await _loadInitial(refreshing: true);
    }
  }

  Future<void> _toggleLike(PostModel post) async {
    if (!_likeRequests.add(post.id)) return;
    setState(() {
      _likeError = null;
    });
    try {
      final status = (post.likedByMe ?? false)
          ? await (widget.postsService ?? PostsService()).unlikePost(post.id)
          : await (widget.postsService ?? PostsService()).likePost(post.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (item) => item.id == post.id
                  ? item.copyWith(
                      likeCount: status.likeCount,
                      likedByMe: status.likedByMe,
                    )
                  : item,
            )
            .toList();
        _likeRequests.remove(post.id);
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _likeRequests.remove(post.id);
        _likeError = error.statusCode == 404
            ? 'Post not found.'
            : 'Couldn\'t update like.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _likeRequests.remove(post.id);
        _likeError = 'Couldn\'t update like.';
      });
    }
  }

  Future<void> _toggleWitness(PostModel post) async {
    if (!_witnessRequests.add(post.id)) return;
    setState(() {
      _witnessError = null;
      _witnessRetryPostId = null;
    });
    try {
      final status = (post.witnessedByMe ?? false)
          ? await (widget.postsService ?? PostsService()).unwitnessPost(
              post.id,
            )
          : await (widget.postsService ?? PostsService()).witnessPost(post.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (item) => item.id == post.id
                  ? item.copyWith(
                      witnessCount: status.witnessCount,
                      witnessedByMe: status.witnessedByMe,
                      verificationStatus: status.verification?.status,
                    )
                  : item,
            )
            .toList();
        _witnessRequests.remove(post.id);
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _witnessRequests.remove(post.id);
        _witnessRetryPostId = post.id;
        _witnessError = error.statusCode == 404
            ? 'Post not found.'
            : 'Couldn\'t update witness.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _witnessRequests.remove(post.id);
        _witnessRetryPostId = post.id;
        _witnessError = 'Couldn\'t update witness.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Local Feed'),
        actions: [
          IconButton(
            onPressed: _isLoading || !_hasLocality ? null : _openComposer,
            icon: const Icon(Icons.add),
            tooltip: 'Create post',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadInitial(refreshing: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Your local feed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_likeError != null)
                    Text(
                      _likeError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (_witnessError != null) ...[
                    Text(
                      _witnessError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    if (_witnessRetryPostId != null)
                      TextButton(
                        onPressed: () {
                          final post = _items.cast<PostModel?>().firstWhere(
                            (item) => item?.id == _witnessRetryPostId,
                            orElse: () => null,
                          );
                          if (post != null) _toggleWitness(post);
                        },
                        child: const Text('RETRY WITNESS'),
                      ),
                  ],
                  if (!_hasLocality) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Set your location to see local posts.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: widget.onUpdateLocation,
                      child: const Text('UPDATE MY LOCATION'),
                    ),
                  ] else if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _loadInitial(),
                      child: const Text('RETRY'),
                    ),
                  ] else if (_items.isEmpty) ...[
                    const SizedBox(height: 32),
                    const Center(child: Text('No local posts yet.')),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openComposer,
                      child: const Text('CREATE POST'),
                    ),
                  ],
                  ..._items.map(_buildPost),
                  if (_nextCursor != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isLoadingMore ? null : _loadMore,
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('LOAD MORE'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPost(PostModel post) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: () => _openPost(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author?.name?.trim().isNotEmpty == true
                    ? post.author!.name!.trim()
                    : 'Khabro User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(post.content),
              const SizedBox(height: 8),
              Text(
                post.createdAt.toLocal().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              VerificationStatusBadge(
                status: post.verificationStatus,
                compact: true,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _likeRequests.contains(post.id)
                        ? null
                        : () => _toggleLike(post),
                    icon: _likeRequests.contains(post.id)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            post.likedByMe == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post.likedByMe == true ? Colors.red : null,
                          ),
                    tooltip: post.likedByMe == true ? 'Unlike' : 'Like',
                  ),
                  Text('${post.likeCount ?? 0}'),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _witnessRequests.contains(post.id)
                        ? null
                        : () => _toggleWitness(post),
                    icon: _witnessRequests.contains(post.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            post.witnessedByMe == true
                                ? Icons.visibility
                                : Icons.visibility_outlined,
                          ),
                    label: Text(
                      post.witnessedByMe == true
                          ? 'Witnessed ${post.witnessCount ?? 0}'
                          : 'Witness ${post.witnessCount ?? 0}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
