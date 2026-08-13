import 'package:flutter/material.dart';

import '../../posts/data/report_reason.dart';

/// Shows a modal report dialog that collects a reason and optional
/// description, then calls [onSubmit]. The dialog handles loading, error, and
/// success states internally and guarantees:
///  - a reason must be selected before submitting;
///  - duplicate taps while a request is in flight are ignored;
///  - on success it replaces the form with "Report submitted" and never
///    reveals an internal report id, reporter identity, or moderation status.
///
/// Returns true when the report was submitted successfully.
Future<bool> showReportDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(ReportReason reason, String? description)
  onSubmit,
}) async {
  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) => _ReportDialog(title: title, onSubmit: onSubmit),
  );
  return submitted ?? false;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.title, required this.onSubmit});

  final String title;
  final Future<void> Function(ReportReason reason, String? description)
  onSubmit;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isSubmitting && _selectedReason != null;

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final description = _descriptionController.text.trim();
      await widget.onSubmit(reason, description.isEmpty ? null : description);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: _submitted
            ? const Text('Report submitted')
            : _buildForm(context),
      ),
      actions: _submitted
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
            ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you reporting this?'),
          const SizedBox(height: 12),
          for (final reason in ReportReason.values)
            ListTile(
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedReason = reason),
              leading: Icon(
                _selectedReason == reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(reason.label),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              hintText: 'Add anything else the moderators should know',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
