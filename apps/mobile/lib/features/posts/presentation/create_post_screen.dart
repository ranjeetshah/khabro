import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../data/post_background.dart';
import '../data/post_category.dart';
import '../data/post_media_model.dart';
import '../data/posts_service.dart';
import 'post_background_card.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    this.postsService,
    this.onPostCreated,
  });

  final PostsService? postsService;
  final VoidCallback? onPostCreated;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _maxLength = 5000;

  final _controller = TextEditingController();
  final _linkController = TextEditingController();

  PostCategory _selectedCategory = PostCategory.general;
  PostBackground _selectedBackground = PostBackground.defaultColor;

  bool _isSubmitting = false;
  bool _isUploadingMedia = false;
  String? _errorMessage;

  final List<PostMediaModel> _attachedMedia = [];

  PostsService get _service => widget.postsService ?? PostsService();

  bool get _hasMedia => _attachedMedia.isNotEmpty;

  bool get _canSubmit =>
      !_isSubmitting && !_isUploadingMedia && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _linkController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _linkController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _selectBackground(PostBackground bg) {
    if (_hasMedia) return; // Background disabled for media posts
    setState(() {
      _selectedBackground = bg;
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _attachedMedia.removeAt(index);
      if (_attachedMedia.isEmpty) {
        // re-enable background
      }
    });
  }

  Future<void> _attachImageMock() async {
    if (_attachedMedia.any((m) => m.type == PostMediaType.video)) {
      setState(() {
        _errorMessage = 'Cannot combine images and video in a single post.';
      });
      return;
    }
    if (_attachedMedia.length >= 4) {
      setState(() {
        _errorMessage = 'Maximum 4 images allowed per post.';
      });
      return;
    }

    setState(() {
      _isUploadingMedia = true;
      _errorMessage = null;
      _selectedBackground = PostBackground.defaultColor; // Reset background for media
    });

    try {
      final mockBytes = List<int>.generate(100, (i) => i);
      final filename = 'image_${_attachedMedia.length + 1}.jpg';
      final media = await _service.uploadMedia(mockBytes, filename, 'image/jpeg');

      if (!mounted) return;
      setState(() {
        _attachedMedia.add(media);
        _isUploadingMedia = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _errorMessage = 'Failed to upload image. Please try again.';
      });
    }
  }

  Future<void> _attachVideoMock() async {
    if (_attachedMedia.isNotEmpty) {
      setState(() {
        _errorMessage = 'Cannot combine images and video or upload multiple videos.';
      });
      return;
    }

    setState(() {
      _isUploadingMedia = true;
      _errorMessage = null;
      _selectedBackground = PostBackground.defaultColor;
    });

    try {
      final mockBytes = List<int>.generate(500, (i) => i);
      final filename = 'video_1.mp4';
      final media = await _service.uploadMedia(mockBytes, filename, 'video/mp4');

      if (!mounted) return;
      setState(() {
        _attachedMedia.add(media);
        _isUploadingMedia = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _errorMessage = 'Failed to upload video. Please try again.';
      });
    }
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

    final linkUrl = _linkController.text.trim();
    if (linkUrl.isNotEmpty) {
      final lower = linkUrl.toLowerCase();
      if (lower.startsWith('javascript:') ||
          lower.startsWith('data:') ||
          lower.startsWith('file:') ||
          lower.startsWith('ftp:')) {
        setState(() => _errorMessage = 'Invalid or unsafe link URL.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final mediaIds = _attachedMedia.map((m) => m.id).where((id) => id.isNotEmpty).toList();

      await _service.createPost(
        content,
        category: _selectedCategory.wireValue,
        background: _hasMedia ? PostBackground.defaultColor : _selectedBackground,
        mediaIds: mediaIds.isNotEmpty ? mediaIds : null,
        linkUrl: linkUrl.isNotEmpty ? linkUrl : null,
      );

      if (!mounted) return;
      _controller.clear();
      _linkController.clear();
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Category Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PostCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Composer Text Input / Live Preview
          if (!_selectedBackground.isDefault && !_hasMedia && _controller.text.trim().isNotEmpty) ...[
            PostBackgroundCard(
              content: _controller.text,
              background: _selectedBackground,
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _controller,
            enabled: !_isSubmitting,
            autofocus: true,
            maxLines: 5,
            maxLength: _maxLength,
            buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
            decoration: const InputDecoration(
              hintText: 'Share something with your area...',
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${_controller.text.length} / $_maxLength'),
          ),
          const SizedBox(height: 12),

          // Background Selector Chips
          Opacity(
            opacity: _hasMedia ? 0.4 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Background Color',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (_hasMedia)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          '(Disabled for media posts)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PostBackground.values
                        .where((bg) => bg != PostBackground.unknown)
                        .map((bg) {
                      final isSelected = bg == _selectedBackground;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: _hasMedia ? null : () => _selectBackground(bg),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: bg.backgroundColor(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: bg.textColor(context),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Link URL Field
          TextField(
            controller: _linkController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.link),
              hintText: 'Optional link URL (https://...)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          // Media Attachment Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: (_isSubmitting || _isUploadingMedia) ? null : _attachImageMock,
                icon: const Icon(Icons.image),
                label: Text('Add Image (${_attachedMedia.where((m) => m.type == PostMediaType.image).length}/4)'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: (_isSubmitting || _isUploadingMedia) ? null : _attachVideoMock,
                icon: const Icon(Icons.videocam),
                label: const Text('Add Video'),
              ),
            ],
          ),

          if (_isUploadingMedia) ...[
            const SizedBox(height: 12),
            Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Uploading media...', style: TextStyle(fontSize: 13, color: Colors.blue)),
              ],
            ),
          ],

          // Attached Media Previews
          if (_attachedMedia.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_attachedMedia.length, (index) {
                final media = _attachedMedia[index];
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          media.type == PostMediaType.image ? Icons.image : Icons.videocam,
                          size: 36,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 20),
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
