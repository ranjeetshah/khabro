import 'package:flutter/material.dart';

import '../data/complaint_model.dart';
import '../data/complaint_service.dart';

/// Shows a citizen's own complaint: description, current status, submitted
/// date, and a status timeline showing only states that actually occurred.
/// No locality, coordinates, or authority internals are displayed.
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    this.complaintService,
  });

  final String complaintId;
  final ComplaintService? complaintService;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late final ComplaintService _complaintService =
      widget.complaintService ?? ComplaintService();
  ComplaintDetailModel? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _detail = null;
    });
    try {
      final detail = await _complaintService.getComplaint(widget.complaintId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load complaint details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Civic complaint')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final detail = _detail;
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          detail.status.label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Submitted ${_formatDate(detail.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(detail.description),
        if (detail.postContent != null) ...[
          const SizedBox(height: 16),
          Text(
            'About the post: ${detail.postContent}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in detail.statusHistory) ...[
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, size: 12),
            title: Text(entry.toStatus.label),
            subtitle: Text(_formatDate(entry.createdAt)),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${_pad(local.year, 4)}-${_pad(local.month, 2)}-'
        '${_pad(local.day, 2)} ${_pad(local.hour, 2)}:'
        '${_pad(local.minute, 2)}';
  }

  String _pad(int value, int width) => value.toString().padLeft(width, '0');
}
