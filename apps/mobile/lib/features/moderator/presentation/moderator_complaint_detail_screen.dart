import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/moderator_civic_complaint_model.dart';
import '../data/moderator_service.dart';

class ModeratorComplaintDetailScreen extends StatefulWidget {
  const ModeratorComplaintDetailScreen({
    super.key,
    required this.moderatorService,
    required this.complaintId,
  });

  final ModeratorService moderatorService;
  final String complaintId;

  @override
  State<ModeratorComplaintDetailScreen> createState() => _ModeratorComplaintDetailScreenState();
}

class _ModeratorComplaintDetailScreenState extends State<ModeratorComplaintDetailScreen> {
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;
  int? _statusCode;
  ModeratorCivicComplaintModel? _complaint;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusCode = null;
    });

    try {
      final data = await widget.moderatorService.getCivicComplaintDetail(widget.complaintId);
      if (!mounted) return;
      setState(() {
        _complaint = data;
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
        _errorMessage = 'Failed to load civic complaint details';
        _isLoading = false;
      });
    }
  }

  Future<void> _transitionStatus(String targetStatus, {String? note}) async {
    setState(() {
      _isActionInProgress = true;
      _errorMessage = null;
    });

    try {
      await widget.moderatorService.updateCivicComplaintStatus(
        _complaint!.id,
        targetStatus,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        _isActionInProgress = false;
      });
      _loadDetail();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isActionInProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to update complaint status';
        _isActionInProgress = false;
      });
    }
  }

  void _showNoteDialog(String targetStatus) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transition to $targetStatus'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter internal notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _transitionStatus(targetStatus, note: controller.text);
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ModeratorCivicComplaintHistoryModel history) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 12, color: Color(0xFF1565C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history.fromStatus ?? 'DRAFT'} → ${history.toStatus}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                if (history.note != null && history.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${history.note}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  history.createdAt.toLocal().toString().split('.')[0],
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_statusCode == 403) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Detail')),
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

    String? nextStatus;
    if (_complaint != null) {
      if (_complaint!.status == 'SENT') {
        nextStatus = 'ACKNOWLEDGED';
      } else if (_complaint!.status == 'ACKNOWLEDGED') {
        nextStatus = 'IN_PROGRESS';
      } else if (_complaint!.status == 'IN_PROGRESS') {
        nextStatus = 'RESOLVED';
      } else if (_complaint!.status == 'REOPENED') {
        nextStatus = 'ACKNOWLEDGED';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Civic Complaint'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _complaint == null
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _complaint!.referenceCode,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _complaint!.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE5E7EB)),
                      _buildDetailRow('Witnesses', '${_complaint!.witnessCount}'),
                      if (_complaint!.sentAt != null)
                        _buildDetailRow('Sent Date', _complaint!.sentAt!.toLocal().toString().split(' ')[0]),
                      _buildDetailRow('Created At', _complaint!.createdAt.toLocal().toString().split(' ')[0]),

                      const SizedBox(height: 16),
                      const Text(
                        'History',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 8),
                      if (_complaint!.statusHistory == null || _complaint!.statusHistory!.isEmpty)
                        const Text(
                          'No history available.',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        )
                      else
                        ..._complaint!.statusHistory!.map((h) => _buildHistoryItem(h)),

                      const SizedBox(height: 32),

                      if (nextStatus != null)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isActionInProgress
                                ? null
                                : () => _showNoteDialog(nextStatus!),
                            child: _isActionInProgress
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                : Text('TRANSITION TO $nextStatus'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
