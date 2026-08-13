import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../feedback/data/feedback_model.dart';
import '../data/moderator_service.dart';
import 'moderator_feedback_detail_screen.dart';

class ModeratorFeedbackListScreen extends StatefulWidget {
  const ModeratorFeedbackListScreen({
    super.key,
    required this.moderatorService,
    this.initialType = 'ALL',
    this.initialStatus = 'OPEN',
  });

  final ModeratorService moderatorService;
  final String initialType;
  final String initialStatus;

  @override
  State<ModeratorFeedbackListScreen> createState() => _ModeratorFeedbackListScreenState();
}

class _ModeratorFeedbackListScreenState extends State<ModeratorFeedbackListScreen> {
  late String _selectedType;
  late String _selectedStatus;

  bool _isLoading = true;
  String? _errorMessage;
  int? _statusCode;

  List<FeedbackModel> _items = [];
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedStatus = widget.initialStatus;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusCode = null;
      _items = [];
      _currentPage = 1;
    });

    try {
      final res = await widget.moderatorService.getFeedbacks(
        page: _currentPage,
        limit: 20,
        type: _selectedType == 'ALL' ? null : _selectedType,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _hasMore = res.hasMore;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _statusCode = e.statusCode;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load feedback';
        _isLoading = false;
      });
    }
  }

  void _changeType(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _loadInitial();
  }

  void _changeStatus(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _loadInitial();
  }

  Widget _buildTypeButton(String type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _changeType(type),
        selectedColor: const Color(0xFF1565C0),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF374151),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusButton(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _changeStatus(status),
        selectedColor: const Color(0xFF1565C0),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF374151),
        ),
        backgroundColor: Colors.white,
      ),
    );
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

  Widget _buildFeedbackItem(FeedbackModel item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: ListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.type.wire,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(item.status).withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status.wire.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(item.status),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              item.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModeratorFeedbackDetailScreen(
                moderatorService: widget.moderatorService,
                feedbackId: item.id,
              ),
            ),
          ).then((_) => _loadInitial());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_statusCode == 403) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feedback')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Moderator privileges required.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('BACK'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeButton('ALL', 'All'),
                  _buildTypeButton('BUG', 'Bugs'),
                  _buildTypeButton('FEEDBACK', 'Feedback'),
                  _buildTypeButton('SUGGESTION', 'Ideas'),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusButton('OPEN', 'Open'),
                  _buildStatusButton('REVIEWED', 'Reviewed'),
                  _buildStatusButton('RESOLVED', 'Resolved'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
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
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadInitial,
                                child: const Text('RETRY'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              'No feedback found.',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _items.length) {
                                return _buildFeedbackItem(_items[index]);
                              }
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
