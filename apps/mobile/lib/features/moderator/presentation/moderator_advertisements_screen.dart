import 'package:flutter/material.dart';

import '../../advertisements/data/advertisement_model.dart';
import '../../advertisements/data/advertisement_service.dart';
import '../../auth/data/auth_exception.dart';
import 'moderator_advertisement_detail_screen.dart';
import 'moderator_advertisement_form_screen.dart';

class ModeratorAdvertisementsScreen extends StatefulWidget {
  const ModeratorAdvertisementsScreen({
    super.key,
    required this.advertisementService,
  });

  final AdvertisementService advertisementService;

  @override
  State<ModeratorAdvertisementsScreen> createState() => _ModeratorAdvertisementsScreenState();
}

class _ModeratorAdvertisementsScreenState extends State<ModeratorAdvertisementsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int? _statusCode;

  List<AdvertisementModel> _items = [];
  int _currentPage = 1;
  bool _hasMore = false;
  String _statusFilter = 'ALL';
  String _placementFilter = 'ALL';

  @override
  void initState() {
    super.initState();
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
      final res = await widget.advertisementService.getModeratorAdvertisements(
        page: _currentPage,
        limit: 20,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        placement: _placementFilter == 'ALL' ? null : _placementFilter,
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
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    final nextPage = _currentPage + 1;
    try {
      final res = await widget.advertisementService.getModeratorAdvertisements(
        page: nextPage,
        limit: 20,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        placement: _placementFilter == 'ALL' ? null : _placementFilter,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...res.items];
        _currentPage = nextPage;
        _hasMore = res.hasMore;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorAdvertisementFormScreen(
          advertisementService: widget.advertisementService,
        ),
      ),
    );
    _loadInitial();
  }

  Future<void> _openDetail(AdvertisementModel ad) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorAdvertisementDetailScreen(
          advertisementService: widget.advertisementService,
          advertisementId: ad.id,
        ),
      ),
    );
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    if (_statusCode == 403) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advertisements')),
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
        title: const Text('Advertisements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create advertisement',
            onPressed: _openCreate,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitial),
        ],
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
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: _items.isEmpty
                          ? const Center(
                              child: Text(
                                'No advertisements yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: _loadMore,
                                        child: const Text('LOAD MORE'),
                                      ),
                                    ),
                                  );
                                }
                                final ad = _items[index];
                                return _buildAdTile(ad);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(value: 'PAUSED', child: Text('Paused')),
                      DropdownMenuItem(value: 'EXPIRED', child: Text('Expired')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadInitial();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    initialValue: _placementFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Placements')),
                      DropdownMenuItem(value: 'FEED', child: Text('Feed')),
                      DropdownMenuItem(value: 'POST_DETAIL', child: Text('Post Detail')),
                      DropdownMenuItem(value: 'PROFILE', child: Text('Profile')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _placementFilter = value;
                      });
                      _loadInitial();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdTile(AdvertisementModel ad) {
    final statusColor = switch (ad.status) {
      AdvertisementStatus.active => const Color(0xFF16A34A),
      AdvertisementStatus.paused => const Color(0xFFD97706),
      AdvertisementStatus.expired => const Color(0xFF6B7280),
      AdvertisementStatus.draft => const Color(0xFF6B7280),
      AdvertisementStatus.unknown => const Color(0xFF6B7280),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => _openDetail(ad),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ad.title.isEmpty ? '(Untitled)' : ad.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ad.status.label.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${ad.advertiserName}  \u2022  ${ad.placement.label}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '${ad.impressionCount} impressions \u2022 ${ad.clickCount} clicks \u2022 CTR ${ad.ctr.toStringAsFixed(1)}%',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}