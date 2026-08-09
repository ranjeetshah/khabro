import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../posts/data/post_model.dart';
import '../data/feed_page_model.dart';
import '../data/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.feedService});

  final FeedService? feedService;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<PostModel> _items = const [];
  String? _nextCursor;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  FeedService get _service => widget.feedService ?? FeedService();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final page = await _service.getFeed();
      if (!mounted) return;
      _applyPage(page, append: false);
    } on AuthException catch (error) {
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
      _showError(error.message, loadingMore: true);
    } catch (_) {
      _showError('Could not load more posts. Please try again.', loadingMore: true);
    }
  }

  void _applyPage(FeedPageModel page, {required bool append}) {
    final existingIds = _items.map((item) => item.id).toSet();
    final newItems = append
        ? page.items.where((item) => !existingIds.contains(item.id)).toList()
        : page.items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Local Feed')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Your local feed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_items.isEmpty && _errorMessage == null) ...[
                    const SizedBox(height: 32),
                    const Center(child: Text('No local posts yet.')),
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
          ],
        ),
      ),
    );
  }
}
