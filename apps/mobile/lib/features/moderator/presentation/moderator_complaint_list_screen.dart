import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/moderator_civic_complaint_model.dart';
import '../data/moderator_service.dart';
import 'moderator_complaint_detail_screen.dart';

class ModeratorComplaintListScreen extends StatefulWidget {
  const ModeratorComplaintListScreen({super.key, required this.moderatorService});

  final ModeratorService moderatorService;

  @override
  State<ModeratorComplaintListScreen> createState() => _ModeratorComplaintListScreenState();
}

class _ModeratorComplaintListScreenState extends State<ModeratorComplaintListScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _statusCode;

  List<ModeratorCivicComplaintModel> _items = [];
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
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
      final res = await widget.moderatorService.getCivicComplaints(_currentPage, 20);
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load civic complaints';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final res = await widget.moderatorService.getCivicComplaints(nextPage, 20);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _currentPage = nextPage;
        _hasMore = res.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildComplaintItem(ModeratorCivicComplaintModel complaint) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: ListTile(
        title: Text(
          complaint.referenceCode,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint.status,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Witnesses: ${complaint.witnessCount}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModeratorComplaintDetailScreen(
                moderatorService: widget.moderatorService,
                complaintId: complaint.id,
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
        appBar: AppBar(title: const Text('Civic Complaints')),
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
        title: const Text('Civic Complaints'),
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
                        'No active civic complaints.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _items.length) {
                          return _buildComplaintItem(_items[index]);
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
    );
  }
}
