import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/post_media_model.dart';
import 'package:mobile/features/posts/presentation/media_player_widget.dart';

void main() {
  group('MediaPlayerWidget', () {
    testWidgets('renders YouTube provider badge and play button for ready video', (tester) async {
      const media = PostMediaModel(
        id: 'vid-1',
        type: PostMediaType.video,
        provider: MediaProvider.youtube,
        url: 'https://www.youtube.com/embed/demo',
        thumbnailUrl: 'https://img.youtube.com/vi/demo/hqdefault.jpg',
        providerMediaId: 'demo',
        processingStatus: MediaProcessingStatus.ready,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPlayerWidget(media: media),
          ),
        ),
      );

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('renders processing indicator for video in processing state', (tester) async {
      const media = PostMediaModel(
        id: 'vid-2',
        type: PostMediaType.video,
        provider: MediaProvider.youtube,
        url: '',
        processingStatus: MediaProcessingStatus.processing,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPlayerWidget(media: media),
          ),
        ),
      );

      expect(find.text('Video processing...'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('renders failure state for failed media processing', (tester) async {
      const media = PostMediaModel(
        id: 'vid-3',
        type: PostMediaType.video,
        provider: MediaProvider.youtube,
        url: '',
        processingStatus: MediaProcessingStatus.failed,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPlayerWidget(media: media),
          ),
        ),
      );

      expect(find.text('Video processing failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
