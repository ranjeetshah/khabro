import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../users/data/public_user_service.dart';
import '../../users/presentation/public_author_profile_screen.dart';
import '../data/post_model.dart';
import '../data/posts_service.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.postsService,
    this.publicUserService,
    this.currentUserId,
    this.onSessionExpired,
  });

  final PostModel post;
  final PostsService? postsService;
  final PublicUserService? publicUserService;
  final String? currentUserId;
  final VoidCallback? onSessionExpired;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isDeleting = false;
  String? _errorMessage;

  PostsService get _postsService => widget.postsService ?? PostsService();

  String get _authorName {
    final name = widget.post.author?.name?.trim();
    return name == null || name.isEmpty ? 'Khabro User' : name;
  }

  Future<void> _openAuthor(BuildContext context) async {
    final authorId = widget.post.author?.id;
    if (authorId == null || authorId.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublicAuthorProfileScreen(
          userId: authorId,
          publicUserService: widget.publicUserService,
          onSessionExpired: widget.onSessionExpired,
        ),
      ),
    );
  }

  bool get _isOwnPost =>
      widget.currentUserId != null &&
      widget.currentUserId == widget.post.authorId;

  Future<void> _confirmDelete() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be removed from your local feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deletePost();
  }

  Future<void> _deletePost() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    try {
      await _postsService.deletePost(widget.post.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isDeleting = false;
        _errorMessage = switch (error.statusCode) {
          403 => 'You can only delete your own posts.',
          404 => 'Post not found.',
          _ => 'Couldn\'t delete this post.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Couldn\'t delete this post.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (_isOwnPost)
            IconButton(
              onPressed: _isDeleting ? null : _confirmDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete post',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: widget.post.author?.id == null
                ? null
                : () => _openAuthor(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _authorName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.post.content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Text(
            widget.post.createdAt.toLocal().toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isDeleting ? null : _deletePost,
              child: const Text('RETRY'),
            ),
          ],
          if (_isDeleting) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
