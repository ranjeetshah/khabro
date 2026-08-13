import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/moderator_report_model.dart';
import '../data/moderator_service.dart';
import 'moderator_report_detail_screen.dart';

class ModeratorReportListScreen extends StatefulWidget {
  const ModeratorReportListScreen({
    super.key,
    required this.moderatorService,
    this.initialType = 'ALL',
  });

  final ModeratorService moderatorService;
  final String initialType;

  @override
  State<ModeratorReportListScreen> createState() => _ModeratorReportListScreenState();
}

class _ModeratorReportListScreenState extends State<ModeratorReportListScreen> {
  final ScrollController _scrollController = ScrollController();
  late String _selectedType;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _statusCode;

  List<ModeratorReportModel> _items = [];
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
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
      final res = await widget.moderatorService.getReports(
        _currentPage,
        20,
        type: _selectedType,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load reports';
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
      final res = await widget.moderatorService.getReports(
        nextPage,
        20,
        type: _selectedType,
      );
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

  void _changeType(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
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
        textColor: isSelected ? Colors.white : const Color(0xFF374151),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildReportItem(ModeratorReportModel report) {
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
                report.type,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: report.status == 'OPEN'
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                report.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: report.status == 'OPEN'
                      ? const Color(0xFFD97706)
                      : const Color(0xFF059669),
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
              'Reason: ${report.reason}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
            ),
            if (report.description != null && report.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                report.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Target: ${report.targetTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModeratorReportDetailScreen(
                moderatorService: widget.moderatorService,
                reportId: report.id,
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
        appBar: AppBar(title: const Text('Reports')),
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
        title: const Text('Reports'),
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
                  _buildTypeButton('POST', 'Posts'),
                  _buildTypeButton('USER', 'Users'),
                  _buildTypeButton('COMMENT', 'Comments'),
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
                              'No reports found.',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _items.length) {
                                return _buildReportItem(_items[index]);
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
}
class ChoiceChip extends StatelessWidget {
  const ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.selectedColor,
    required this.textColor,
    required this.backgroundColor,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color selectedColor;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? selectedColor : const Color(0xFFE5E7EB)),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          child: label,
        ),
      ),
    );
  }
}
