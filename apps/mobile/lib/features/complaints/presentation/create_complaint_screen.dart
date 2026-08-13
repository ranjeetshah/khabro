import 'package:flutter/material.dart';

import '../../posts/data/post_model.dart';
import '../data/complaint_service.dart';
import 'complaint_detail_screen.dart';

/// Lets a citizen formally submit a civic complaint for a locally verified
/// post. Only the post's content is referenced; no locality, coordinates, or
/// authority internals are shown or sent beyond the required description.
class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({
    super.key,
    required this.post,
    this.complaintService,
  });

  final PostModel post;
  final ComplaintService? complaintService;

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  late final ComplaintService _complaintService =
      widget.complaintService ?? ComplaintService();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _descriptionController.text.trim().length >= 10;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final submission = await _complaintService.createComplaint(
        widget.post.id,
        _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ComplaintDetailScreen(
            complaintId: submission.id,
            complaintService: widget.complaintService,
          ),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Submit civic complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'About this post:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLength: 2000,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'What is the issue?',
                hintText: 'Describe the verified local issue (min 10 characters)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit complaint'),
            ),
          ],
        ),
      ),
    );
  }
}
