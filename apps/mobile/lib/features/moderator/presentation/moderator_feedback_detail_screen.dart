import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../feedback/data/feedback_model.dart';
import '../data/moderator_service.dart';

class ModeratorFeedbackDetailScreen extends StatefulWidget {
  const ModeratorFeedbackDetailScreen({
    super.key,
    required this.moderatorService,
    required this.feedbackId,
  });

  final ModeratorService moderatorService;
  final String feedbackId;

  @override
  State<ModeratorFeedbackDetailScreen> createState() => _ModeratorFeedbackDetailScreenState();
}

class _ModeratorFeedbackDetailScreenState extends State<ModeratorFeedbackDetailScreen> {
  late final ModeratorService _moderatorService;
  FeedbackModel? _feedback;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  int? _statusCode;

  @override
  void initState() {
    super.initState();
    _moderatorService = widget.moderatorService;
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusCode = null;
    });

    try {
      final feedback = await _moderatorService.getFeedbackDetail(widget.feedbackId);
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _statusCode = e.statusCode;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load feedback';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      await _moderatorService.updateFeedbackStatus(widget.feedbackId, status);
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
      });
      _loadFeedback();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _errorMessage = e.message;
        _statusCode = e.statusCode;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _errorMessage = 'Failed to update status';
      });
    }
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
      appBar: AppBar(
        title: const Text('Feedback Detail'),
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
                          onPressed: _loadFeedback,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : _feedback == null
                  ? const Center(child: Text('Feedback not found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildInfoRow('Type', _feedback!.type.wire),
                        const Divider(height: 24),
                        _buildInfoRow('Status', _feedback!.status.wire.toUpperCase()),
                        const Divider(height: 24),
                        _buildInfoRow('Created', _formatDate(_feedback!.createdAt)),
                        if (_feedback!.appVersion != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow('App Version', _feedback!.appVersion!),
                        ],
                        if (_feedback!.platform != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow('Platform', _feedback!.platform!),
                        ],
                        const Divider(height: 24),
                        const Text(
                          'Message',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(_feedback!.message),
                        const SizedBox(height: 24),
                        if (_feedback!.status == FeedbackStatus.open)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : () => _updateStatus('REVIEWED'),
                              child: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text('MARK REVIEWED'),
                            ),
                          ),
                        if (_feedback!.status == FeedbackStatus.reviewed)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : () => _updateStatus('RESOLVED'),
                              child: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text('RESOLVE'),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
