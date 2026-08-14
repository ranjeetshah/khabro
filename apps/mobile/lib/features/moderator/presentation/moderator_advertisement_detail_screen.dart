import 'package:flutter/material.dart';

import '../../advertisements/data/advertisement_model.dart';
import '../../advertisements/data/advertisement_service.dart';
import '../../auth/data/auth_exception.dart';
import 'moderator_advertisement_form_screen.dart';

class ModeratorAdvertisementDetailScreen extends StatefulWidget {
  const ModeratorAdvertisementDetailScreen({
    super.key,
    required this.advertisementService,
    required this.advertisementId,
  });

  final AdvertisementService advertisementService;
  final String advertisementId;

  @override
  State<ModeratorAdvertisementDetailScreen> createState() => _ModeratorAdvertisementDetailScreenState();
}

class _ModeratorAdvertisementDetailScreenState extends State<ModeratorAdvertisementDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AdvertisementModel? _ad;
  bool _busy = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ad = await widget.advertisementService.getModeratorAdvertisementDetail(
        widget.advertisementId,
      );
      if (!mounted) return;
      setState(() {
        _ad = ad;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
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

  Future<void> _runAction(Future<AdvertisementModel> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _ad = updated;
        _busy = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actionError = 'An unexpected error occurred. Please try again.';
        _busy = false;
      });
    }
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorAdvertisementFormScreen(
          advertisementService: widget.advertisementService,
          advertisementId: widget.advertisementId,
        ),
      ),
    );
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Advertisement'),
        actions: [
          if (_ad != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _busy ? null : _openEdit,
            ),
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
                          onPressed: _loadDetail,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildDetail(_ad!),
    );
  }

  Widget _buildDetail(AdvertisementModel ad) {
    final now = DateTime.now();
    final expired = ad.endAt != null && ad.endAt!.isBefore(now);
    final notStarted = ad.startAt != null && ad.startAt!.isAfter(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad.title.isEmpty ? '(Untitled)' : ad.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
              if (ad.description != null && ad.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ad.description!,
                  style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              _detailRow('Status', ad.status.label),
              _detailRow('Placement', ad.placement.label),
              _detailRow('Advertiser', ad.advertiserName),
              _detailRow('CTA', ad.ctaLabel ?? 'Learn more'),
              _detailRow('Creative URL', ad.creativeUrl),
              _detailRow('Destination URL', ad.destinationUrl),
              _detailRow('Start', ad.startAt?.toLocal().toString().substring(0, 16) ?? 'Not set'),
              _detailRow('End', ad.endAt?.toLocal().toString().substring(0, 16) ?? 'Not set'),
              const Divider(height: 24),
              _detailRow('Impressions', '${ad.impressionCount}'),
              _detailRow('Clicks', '${ad.clickCount}'),
              _detailRow('CTR', '${ad.ctr.toStringAsFixed(2)}%'),
              if (expired || notStarted) ...[
                const SizedBox(height: 8),
                Text(
                  expired
                      ? 'This advertisement has reached its end date.'
                      : 'This advertisement has not started yet.',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 12),
          Text(
            _actionError!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        ..._buildActions(ad),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AdvertisementModel ad) {
    switch (ad.status) {
      case AdvertisementStatus.active:
        return [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _runAction(
                      () => widget.advertisementService.pauseAdvertisement(ad.id),
                    ),
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('PAUSE'),
            ),
          ),
        ];
      case AdvertisementStatus.paused:
      case AdvertisementStatus.draft:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _runAction(
                      () => widget.advertisementService.activateAdvertisement(ad.id),
                    ),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('ACTIVATE'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _showCancelDialog(ad),
              icon: const Icon(Icons.delete_outline),
              label: const Text('CANCEL'),
            ),
          ),
        ];
      case AdvertisementStatus.expired:
      case AdvertisementStatus.unknown:
        return const [];
    }
  }

  Future<void> _showCancelDialog(AdvertisementModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel advertisement?'),
        content: Text(
          'This will cancel \u201c${ad.title.isEmpty ? '(Untitled)' : ad.title}\u201d. It will no longer be shown to users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('KEEP'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CANCEL AD', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      await widget.advertisementService.cancelAdvertisement(ad.id);
      return ad;
    });
  }
}