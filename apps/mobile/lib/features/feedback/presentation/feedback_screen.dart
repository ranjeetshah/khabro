import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/data/auth_exception.dart';
import '../data/feedback_model.dart';
import '../data/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    this.feedbackService,
    this.onFeedbackSubmitted,
    this.onSessionExpired,
  });

  final FeedbackService? feedbackService;
  final VoidCallback? onFeedbackSubmitted;
  final VoidCallback? onSessionExpired;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final FeedbackService _feedbackService;
  final TextEditingController _messageController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.feedback;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _appVersion;
  String? _platform;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
        _platform = 'flutter';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersion = null;
        _platform = null;
      });
    }
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _errorMessage = 'Please tell us what happened.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _feedbackService.submitFeedback(
        type: _selectedType,
        message: message,
        appVersion: _appVersion,
        platform: _platform,
      );
      if (!mounted) return;
      setState(() {
        _isSuccess = true;
        _isSubmitting = false;
      });
      widget.onFeedbackSubmitted?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) widget.onSessionExpired?.call();
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Couldn\'t send feedback. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: _isSuccess
          ? _buildSuccess()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Help us improve Khabro.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                ..._buildTypeSelector(),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Tell us what happened...',
                    alignLabelWithHint: true,
                  ),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('SEND FEEDBACK'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSuccess() {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF1565C0)),
          SizedBox(height: 16),
          Text(
            'Thanks for helping improve Khabro.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSelector() {
    return [
      const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _TypeChip(
              label: 'Bug',
              selected: _selectedType == FeedbackType.bug,
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedType = FeedbackType.bug),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeChip(
              label: 'Feedback',
              selected: _selectedType == FeedbackType.feedback,
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedType = FeedbackType.feedback),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeChip(
              label: 'Idea',
              selected: _selectedType == FeedbackType.suggestion,
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedType = FeedbackType.suggestion),
            ),
          ),
        ],
      ),
    ];
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF374151),
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
