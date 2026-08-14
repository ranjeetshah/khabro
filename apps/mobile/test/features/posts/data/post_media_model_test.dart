import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/post_media_model.dart';

void main() {
  group('PostMediaModel', () {
    test('deserializes complete YouTube video json safely', () {
      final json = {
        'id': 'media-1',
        'type': 'VIDEO',
        'provider': 'YOUTUBE',
        'url': 'https://www.youtube.com/embed/xyz123',
        'thumbnailUrl': 'https://img.youtube.com/vi/xyz123/hqdefault.jpg',
        'providerMediaId': 'xyz123',
        'mimeType': 'video/mp4',
        'processingStatus': 'READY',
      };

      final model = PostMediaModel.fromJson(json);

      expect(model.id, 'media-1');
      expect(model.type, PostMediaType.video);
      expect(model.provider, MediaProvider.youtube);
      expect(model.url, 'https://www.youtube.com/embed/xyz123');
      expect(model.providerMediaId, 'xyz123');
      expect(model.processingStatus, MediaProcessingStatus.ready);
    });

    test('falls back safely on unknown enum values', () {
      final json = {
        'id': 'media-2',
        'type': 'FUTURE_HOLOGRAM',
        'provider': 'FUTURE_PROVIDER',
        'url': 'https://example.com/media',
        'processingStatus': 'SUPER_FAST',
      };

      final model = PostMediaModel.fromJson(json);

      expect(model.type, PostMediaType.unknown);
      expect(model.provider, MediaProvider.unknown);
      expect(model.processingStatus, MediaProcessingStatus.unknown);
    });

    test('serializes to JSON correctly', () {
      const model = PostMediaModel(
        id: 'media-3',
        type: PostMediaType.image,
        provider: MediaProvider.khbroCdn,
        url: 'https://cdn.khabro.org/img.jpg',
        processingStatus: MediaProcessingStatus.ready,
      );

      final json = model.toJson();

      expect(json['id'], 'media-3');
      expect(json['type'], 'IMAGE');
      expect(json['provider'], 'KHABRO_CDN');
      expect(json['url'], 'https://cdn.khabro.org/img.jpg');
      expect(json['processingStatus'], 'READY');
    });
  });
}
