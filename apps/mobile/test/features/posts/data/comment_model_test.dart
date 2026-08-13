import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/comment_model.dart';

void main() {
  group('CommentModel', () {
    test('fromJson parses comment and author fields correctly', () {
      final json = {
        'id': 'comment-123',
        'content': 'Haan maine dekha hai',
        'createdAt': '2026-08-13T10:20:30.000Z',
        'author': {
          'id': 'user-456',
          'name': 'Amit',
        },
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.id, 'comment-123');
      expect(comment.content, 'Haan maine dekha hai');
      expect(comment.authorId, 'user-456');
      expect(comment.authorName, 'Amit');
    });

    test('fromJson handles missing optional author name gracefully', () {
      final json = {
        'id': 'comment-123',
        'content': 'Haan maine dekha hai',
        'createdAt': '2026-08-13T10:20:30.000Z',
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.id, 'comment-123');
      expect(comment.authorId, '');
      expect(comment.authorName, 'Anonymous');
    });
  });
}
