import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';

class FakePostsService extends PostsService {
  FakePostsService() : super(apiClient: null, tokenStorage: null);

  final post = PostModel(
    id: 'post-1',
    authorId: 'user-1',
    localityId: 'development-locality-a',
    content: 'Hello from the test post',
    createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
    updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  );
  var deleted = false;

  @override
  Future<PostModel> createPost(String content) async => post;

  @override
  Future<void> deletePost(String id) async => deleted = true;
}

const testUser = UserModel(
  id: 'user-1',
  phone: '+919876543210',
  name: 'Test User',
  trustScore: 0,
  status: 'ACTIVE',
);

void main() {
  testWidgets('creates and deletes a test post', (tester) async {
    final service = FakePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: testUser, onLogout: () {}, postsService: service),
      ),
    );

    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Hello from the test post');
    final create = find.text('CREATE TEST POST');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(find.text('Hello from the test post'), findsOneWidget);
    final delete = find.byTooltip('Delete post');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();

    expect(service.deleted, isTrue);
    expect(find.text('Hello from the test post'), findsNothing);
  });
}
