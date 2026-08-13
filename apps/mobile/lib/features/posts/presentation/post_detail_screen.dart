import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../complaints/data/complaint_service.dart';
import '../../complaints/presentation/create_complaint_screen.dart';
import '../../reports/presentation/report_dialog.dart';
import '../../users/data/public_user_service.dart';
import '../../users/presentation/public_author_profile_screen.dart';
import '../data/civic_complaint_model.dart';
import '../data/post_model.dart';
import '../data/posts_service.dart';
import '../data/verification_event.dart';
import '../data/verification_history_model.dart';
import '../data/verification_status.dart';
import '../data/witness_status_model.dart';
import 'verification_status_badge.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.postsService,
    this.publicUserService,
    this.complaintService,
    this.currentUserId,
    this.onSessionExpired,
  });

  final PostModel post;
  final PostsService? postsService;
  final PublicUserService? publicUserService;
  final ComplaintService? complaintService;
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
  VerificationHistoryModel? _history;
  CivicComplaintModel? _civicComplaint;
  bool _isActionInProgress = false;
  bool _isHistoryLoading = false;
  String? _historyError;
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
    _loadHistory();
    _loadCivicComplaint();
  }

  Future<void> _confirmResolution() async {
    if (_civicComplaint == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    try {
      final updated = await _postsService.confirmCivicComplaintResolution(
        _civicComplaint!.referenceCode,
      );
      if (!mounted) return;
      setState(() {
        _civicComplaint = updated;
        _isActionInProgress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _showReopenDialog() async {
    if (_civicComplaint == null || _isActionInProgress) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reopen Complaint'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Reason for reopening',
            hintText: 'Describe why the issue is not resolved',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(dialogContext).pop(text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isActionInProgress = true);
      try {
        final updated = await _postsService.reopenCivicComplaint(
          _civicComplaint!.referenceCode,
          reason,
        );
        if (!mounted) return;
        setState(() {
          _civicComplaint = updated;
          _isActionInProgress = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isActionInProgress = false);
      }
    }
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
      if (verification.status == VerificationStatus.locallyVerified) {
        await _loadCivicComplaint();
      }
    } catch (_) {
      // Verification is display-only; keep the value from the post model.
    }
  }

  Future<void> _loadCivicComplaint() async {
    try {
      final complaint = await _postsService.getCivicComplaint(widget.post.id);
      if (!mounted) return;
      setState(() {
        _civicComplaint = complaint;
      });
    } catch (_) {
      // Safe fallback if no complaint exists
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });
    try {
      final history = await _postsService.getVerificationHistory(
        widget.post.id,
      );
      if (!mounted) return;
      setState(() {
        _history = history;
        _isHistoryLoading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isHistoryLoading = false;
        _historyError = "Couldn't load verification history.";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isHistoryLoading = false;
        _historyError = "Couldn't load verification history.";
      });
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

  Future<void> _openReport(BuildContext context) async {
    await showReportDialog(
      context,
      title: 'Report post',
      onSubmit: (reason, description) => _postsService.reportPost(
        widget.post.id,
        reason: reason.wire,
        description: description,
      ),
    );
  }

  Future<void> _openCreateComplaint(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreateComplaintScreen(
          post: widget.post,
          complaintService: widget.complaintService,
        ),
      ),
    );
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
      } else if (status.verification!.status ==
          VerificationStatus.locallyVerified) {
        await _loadCivicComplaint();
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
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'report') _openReport(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'report', child: Text('Report post')),
            ],
          ),
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
          if (_verificationStatus == VerificationStatus.locallyVerified) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Community Complaint',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_civicComplaint != null) ...[
                      Text(
                        'Reference: ${_civicComplaint!.referenceCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${_formatComplaintStatus(_civicComplaint!.status)}',
                        style: TextStyle(
                          color: _statusColor(_civicComplaint!.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_civicComplaint!.status == 'SENT')
                        const Text(
                          'Complaint sent to the concerned authority.',
                          style: TextStyle(color: Colors.green, fontSize: 13),
                        )
                      else if (_civicComplaint!.status == 'ACKNOWLEDGED')
                        const Text(
                          'Complaint acknowledged by authority.',
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        )
                      else if (_civicComplaint!.status == 'IN_PROGRESS')
                        const Text(
                          'Authority work is currently in progress.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        )
                      else if (_civicComplaint!.status == 'RESOLVED') ...[
                        const Text(
                          'Has this issue actually been resolved?',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _isActionInProgress ? null : _confirmResolution,
                                child: const Text('Confirm Resolution'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isActionInProgress ? null : _showReopenDialog,
                                child: const Text('Reopen Complaint'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_civicComplaint!.status == 'CITIZEN_CONFIRMED')
                        const Text(
                          'Resolution confirmed by community.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        )
                      else if (_civicComplaint!.status == 'REOPENED')
                        const Text(
                          'Complaint reopened.',
                          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        )
                      else if (_civicComplaint!.status == 'FAILED')
                        const Text(
                          'Complaint could not be sent.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                    ] else ...[
                      const Text(
                        'Community verification complete.',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openCreateComplaint(context),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Submit Civic Complaint'),
            ),
          ],
          const Divider(height: 32),
          _VerificationHistorySection(
            isLoading: _isHistoryLoading,
            history: _history,
            errorMessage: _historyError,
            onRetry: _loadHistory,
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

/// Human-readable label for a verification event. Never exposes identities.
String verificationEventLabel(VerificationEventModel event) {
  switch (event.type) {
    case VerificationEventType.postCreated:
      return 'Post reported locally';
    case VerificationEventType.witnessAdded:
      return 'A community member witnessed this';
    case VerificationEventType.witnessRemoved:
      return 'A community witness was removed';
    case VerificationEventType.statusChanged:
      return 'Verification status changed to '
          '${verificationStatusName(event.toStatus)}';
    case VerificationEventType.unknown:
      return 'Verification activity';
  }
}

/// Neutral name for a verification status inside the history timeline.
String verificationStatusName(VerificationStatus? status) {
  return switch (status) {
    VerificationStatus.reported => 'Reported',
    VerificationStatus.underVerification => 'Under verification',
    VerificationStatus.locallyVerified => 'Locally verified',
    VerificationStatus.unknown || null => 'a new status',
  };
}

/// Privacy-safe verification timeline for a post. Only event metadata is
/// shown — never witness identities, phone, locality, or coordinates.
class _VerificationHistorySection extends StatelessWidget {
  const _VerificationHistorySection({
    required this.isLoading,
    required this.history,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final VerificationHistoryModel? history;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification history',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (errorMessage != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('RETRY HISTORY'),
              ),
            ],
          )
        else if (history == null || history!.events.isEmpty)
          const Text(
            'No verification activity yet.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else
          ...history!.events.map(
            (event) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      Icons.circle_outlined,
                      size: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verificationEventLabel(event),
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          _formatEventTime(event.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatEventTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

String _formatComplaintStatus(String status) {
  return switch (status) {
    'DRAFT' => 'Draft',
    'SENT' => 'Sent',
    'FAILED' => 'Failed',
    'ACKNOWLEDGED' => 'Acknowledged',
    'IN_PROGRESS' => 'In Progress',
    'RESOLVED' => 'Resolved',
    'CITIZEN_CONFIRMED' => 'Confirmed',
    'REOPENED' => 'Reopened',
    _ => status,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'SENT' || 'CITIZEN_CONFIRMED' => Colors.green,
    'ACKNOWLEDGED' => Colors.blue,
    'IN_PROGRESS' => Colors.orange,
    'RESOLVED' => Colors.teal,
    'REOPENED' => Colors.deepOrange,
    'FAILED' => Colors.red,
    _ => Colors.grey,
  };
}
