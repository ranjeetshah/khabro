import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/posts_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.postsService, this.onPostCreated});

  final PostsService? postsService;
  final VoidCallback? onPostCreated;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _maxLength = 5000;

  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  PostsService get _service => widget.postsService ?? PostsService();

  bool get _canSubmit => !_isSubmitting && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = 'Post content cannot be empty.');
      return;
    }
    if (content.length > _maxLength) {
      setState(() => _errorMessage = 'Posts can contain at most 5,000 characters.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _service.createPost(content);
      if (!mounted) return;
      _controller.clear();
      widget.onPostCreated?.call();
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not create post. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "What's happening locally?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_isSubmitting,
            autofocus: true,
            maxLines: 8,
            maxLength: _maxLength,
            decoration: const InputDecoration(
              hintText: 'Share something with your area',
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${_controller.text.length} / $_maxLength'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('POST'),
            ),
          ),
        ],
      ),
    );
  }
}
