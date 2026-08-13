import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/feedback_model.dart';
import '../data/feedback_service.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({
    super.key,
    this.feedbackService,
    this.onSessionExpired,
  });

  final FeedbackService? feedbackService;
  final VoidCallback? onSessionExpired;

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  late final FeedbackService _feedbackService;
  List<FeedbackModel> _items = [];
  int _page = 1;
  bool _hasMore = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
    _loadFeedback();
  }

  Future<void> _loadFeedback({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (!_isLoading) {
      return;
    }

    try {
      final page = await _feedbackService.getMyFeedback(page: _page, limit: 20);
      if (!mounted) return;
      setState(() {
        _items = refresh ? page.items : [..._items, ...page.items];
        _hasMore = page.hasMore;
        _isLoading = false;
        _errorMessage = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Couldn\'t load feedback. Please try again.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _page += 1;
    });
    await _loadFeedback();
  }

  Color _statusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.open:
        return const Color(0xFFF59E0B);
      case FeedbackStatus.reviewed:
        return const Color(0xFF1565C0);
      case FeedbackStatus.resolved:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feedback'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadFeedback(refresh: true),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'You haven\'t sent any feedback yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: TextButton(
                                onPressed: _loadMore,
                                child: const Text('LOAD MORE'),
                              ),
                            ),
                          );
                        }

                        final item = _items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              item.type.wire,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_formatDate(item.createdAt)} • ${item.status.wire}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(item.status).withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.status.wire.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(item.status),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
