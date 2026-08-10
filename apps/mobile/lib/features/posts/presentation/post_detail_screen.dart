import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../users/data/public_user_service.dart';
import '../../users/presentation/public_author_profile_screen.dart';
import '../data/post_model.dart';
import '../data/posts_service.dart';
import '../data/verification_status.dart';
import '../data/witness_status_model.dart';
import 'verification_status_badge.dart';

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
  bool _isLikeUpdating = false;
  int _likeCount = 0;
  bool _likedByMe = false;
  bool _isWitnessUpdating = false;
  int _witnessCount = 0;
  bool _witnessedByMe = false;
  VerificationStatus _verificationStatus = VerificationStatus.reported;
  String? _errorMessage;
  String? _likeError;
  String? _witnessError;

  PostsService get _postsService => widget.postsService ?? PostsService();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount ?? 0;
    _likedByMe = widget.post.likedByMe ?? false;
    _witnessCount = widget.post.witnessCount ?? 0;
    _witnessedByMe = widget.post.witnessedByMe ?? false;
    _verificationStatus = widget.post.verificationStatus;
    _loadVerification();
  }

  Future<void> _loadVerification() async {
    try {
      final verification = await _postsService.getVerificationStatus(
        widget.post.id,
      );
      if (!mounted) return;
      setState(() {
        _verificationStatus = verification.status;
      });
    } catch (_) {
      // Verification is display-only; keep the value from the post model.
    }
  }

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

  Future<void> _toggleLike() async {
    if (_isLikeUpdating) return;
    _isLikeUpdating = true;
    setState(() {
      _likeError = null;
    });
    try {
      final status = _likedByMe
          ? await _postsService.unlikePost(widget.post.id)
          : await _postsService.likePost(widget.post.id);
      if (!mounted) return;
      setState(() {
        _likeCount = status.likeCount;
        _likedByMe = status.likedByMe;
        _isLikeUpdating = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isLikeUpdating = false;
        _likeError = error.statusCode == 404
            ? 'Post not found.'
            : 'Couldn\'t update like.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLikeUpdating = false;
        _likeError = 'Couldn\'t update like.';
      });
    }
  }

  Future<void> _toggleWitness() async {
    if (_isWitnessUpdating) return;
    _isWitnessUpdating = true;
    setState(() {
      _witnessError = null;
    });
    try {
      final WitnessStatusModel status = _witnessedByMe
          ? await _postsService.unwitnessPost(widget.post.id)
          : await _postsService.witnessPost(widget.post.id);
      if (!mounted) return;
      setState(() {
        _witnessCount = status.witnessCount;
        _witnessedByMe = status.witnessedByMe;
        if (status.verification != null) {
          _verificationStatus = status.verification!.status;
        }
        _isWitnessUpdating = false;
      });
      if (status.verification == null) {
        await _loadVerification();
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isWitnessUpdating = false;
        _witnessError = error.statusCode == 404
            ? 'Post not found.'
            : 'Couldn\'t update witness.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isWitnessUpdating = false;
        _witnessError = 'Couldn\'t update witness.';
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
          const Divider(height: 32),
          VerificationStatusBadge(status: _verificationStatus),
          const SizedBox(height: 8),
          Text(
            'Witnesses: $_witnessCount',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _isLikeUpdating ? null : _toggleLike,
                icon: _isLikeUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: _likedByMe ? Colors.red : null,
                      ),
                tooltip: _likedByMe ? 'Unlike' : 'Like',
              ),
              Text('$_likeCount'),
            ],
          ),
          if (_likeError != null)
            Text(_likeError!, style: const TextStyle(color: Colors.red)),
          TextButton.icon(
            onPressed: _isWitnessUpdating ? null : _toggleWitness,
            icon: _isWitnessUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _witnessedByMe
                        ? Icons.visibility
                        : Icons.visibility_outlined,
                  ),
            label: Text(
              _witnessedByMe ? 'Witnessed' : 'I Witnessed This',
            ),
          ),
          if (_witnessError != null) ...[
            Text(_witnessError!, style: const TextStyle(color: Colors.red)),
            OutlinedButton(
              onPressed: _isWitnessUpdating ? null : _toggleWitness,
              child: const Text('RETRY WITNESS'),
            ),
          ],
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
