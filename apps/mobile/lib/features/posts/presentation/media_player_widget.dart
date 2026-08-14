import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/post_media_model.dart';

class MediaPlayerWidget extends StatelessWidget {
  const MediaPlayerWidget({
    super.key,
    required this.media,
    this.height,
  });

  final PostMediaModel media;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (media.processingStatus == MediaProcessingStatus.uploading) {
      return _buildStatusPlaceholder(
        context,
        icon: Icons.cloud_upload_outlined,
        label: 'Uploading video...',
      );
    }

    if (media.processingStatus == MediaProcessingStatus.processing) {
      return _buildStatusPlaceholder(
        context,
        icon: Icons.sync,
        label: 'Video processing...',
      );
    }

    if (media.processingStatus == MediaProcessingStatus.failed) {
      return _buildStatusPlaceholder(
        context,
        icon: Icons.error_outline,
        label: 'Video processing failed',
        color: Colors.red.shade700,
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty)
              Image.network(
                media.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.movie, color: Colors.white54, size: 48),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(Icons.movie, color: Colors.white54, size: 48),
                ),
              ),

            // Play Button Overlay
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _playVideo(context),
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(165),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Provider Badge (YouTube or Khabro CDN)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(190),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      media.provider == MediaProvider.youtube
                          ? Icons.play_circle_fill
                          : Icons.cloud,
                      color: media.provider == MediaProvider.youtube
                          ? Colors.red
                          : Colors.blue,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      media.provider == MediaProvider.youtube
                          ? 'YouTube'
                          : 'Khabro CDN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playVideo(BuildContext context) async {
    final videoUrl = media.url.isNotEmpty
        ? media.url
        : (media.providerMediaId != null
            ? 'https://www.youtube.com/watch?v=${media.providerMediaId}'
            : null);

    if (videoUrl != null) {
      final uri = Uri.parse(videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
