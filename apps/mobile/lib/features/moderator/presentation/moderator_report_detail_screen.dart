import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/moderator_report_model.dart';
import '../data/moderator_service.dart';

class ModeratorReportDetailScreen extends StatefulWidget {
  const ModeratorReportDetailScreen({
    super.key,
    required this.moderatorService,
    required this.reportId,
  });

  final ModeratorService moderatorService;
  final String reportId;

  @override
  State<ModeratorReportDetailScreen> createState() => _ModeratorReportDetailScreenState();
}

class _ModeratorReportDetailScreenState extends State<ModeratorReportDetailScreen> {
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;
  int? _statusCode;
  ModeratorReportDetailModel? _report;

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
      final data = await widget.moderatorService.getReportDetail(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = data;
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
        _errorMessage = 'Failed to load report details';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isActionInProgress = true;
      _errorMessage = null;
    });

    try {
      await widget.moderatorService.updateReportStatus(widget.reportId, status);
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
        _errorMessage = 'Failed to update status';
        _isActionInProgress = false;
      });
    }
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

  Widget _buildReportedContentBox(String header, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_statusCode == 403) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Detail')),
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

    final isResolvedOrDismissed = _report != null &&
        (_report!.status == 'RESOLVED' || _report!.status == 'DISMISSED');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_report != null ? 'Reported ${_report!.type}' : 'Report Detail'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _report == null
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
                            'Report ID: ${_report!.id.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _report!.status == 'OPEN'
                                  ? const Color(0xFFFEF3C7)
                                  : _report!.status == 'REVIEWED'
                                      ? const Color(0xFFE0F2FE)
                                      : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _report!.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _report!.status == 'OPEN'
                                    ? const Color(0xFFD97706)
                                    : _report!.status == 'REVIEWED'
                                        ? const Color(0xFF0369A1)
                                        : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE5E7EB)),
                      _buildDetailRow('Reason', _report!.reason),
                      if (_report!.description != null && _report!.description!.isNotEmpty)
                        _buildDetailRow('Description', _report!.description!),

                      const SizedBox(height: 12),

                      // Post Detail Section
                      if (_report!.type == 'POST') ...[
                        _buildReportedContentBox('POST CONTENT', _report!.postContent ?? ''),
                        const SizedBox(height: 12),
                        _buildDetailRow('Author', _report!.postAuthorName ?? 'Anonymous'),
                        _buildDetailRow('Verification Status', _report!.postVerificationStatus ?? 'Reported'),
                        _buildDetailRow('Witness Count', '${_report!.postWitnessCount ?? 0}'),
                      ],

                      // User Detail Section
                      if (_report!.type == 'USER') ...[
                        _buildDetailRow('Reported User', _report!.reportedUserName ?? 'Anonymous'),
                        _buildDetailRow('Account Status', _report!.reportedUserStatus ?? 'ACTIVE'),
                        _buildDetailRow('System Role', _report!.reportedUserRole ?? 'CITIZEN'),
                      ],

                      // Comment Detail Section
                      if (_report!.type == 'COMMENT') ...[
                        _buildReportedContentBox('COMMENT CONTENT', _report!.commentContent ?? ''),
                        const SizedBox(height: 12),
                        _buildDetailRow('Comment Author', _report!.commentAuthorName ?? 'Anonymous'),
                        const SizedBox(height: 12),
                        _buildReportedContentBox('RELATED POST CONTENT', _report!.commentPostContent ?? ''),
                      ],

                      const SizedBox(height: 32),

                      if (!isResolvedOrDismissed) ...[
                        if (_report!.status == 'OPEN') ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isActionInProgress ? null : () => _updateStatus('REVIEWED'),
                              child: _isActionInProgress
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                  : const Text('MARK REVIEWED'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isActionInProgress ? null : () => _updateStatus('RESOLVED'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('RESOLVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isActionInProgress ? null : () => _updateStatus('DISMISSED'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('DISMISS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
