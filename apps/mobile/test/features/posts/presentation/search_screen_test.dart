import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/post_category.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/presentation/search_screen.dart';

class FakePostsService extends PostsService {
  FakePostsService() : super(apiClient: null, tokenStorage: null);

  List<PostModel> searchResults = [];
  bool shouldThrow = false;
  int searchCalls = 0;
  String? lastQuery;
  String? lastCategory;
  bool? lastVerified;
  bool? lastRecent;

  @override
  Future<SearchPostsResponse> searchPosts({
    String? query,
    String? category,
    bool? verified,
    bool? recent,
    double? radiusKm,
    int page = 1,
    int limit = 20,
  }) async {
    searchCalls++;
    lastQuery = query;
    lastCategory = category;
    lastVerified = verified;
    lastRecent = recent;

    if (shouldThrow) throw Exception('Failed to search posts');

    return SearchPostsResponse(
      items: searchResults,
      page: page,
      limit: limit,
      hasNextPage: false,
    );
  }
}

void main() {
  test('PostCategory parses wire values safely with fallback', () {
    expect(PostCategory.fromWire('INFRASTRUCTURE'), equals(PostCategory.infrastructure));
    expect(PostCategory.fromWire('INVALID'), equals(PostCategory.general));
  });

  testWidgets('renders initial search state', (tester) async {
    final service = FakePostsService();

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search local posts'), findsOneWidget);
  });

  testWidgets('performs search and displays results', (tester) async {
    final service = FakePostsService();
    service.searchResults = [
      PostModel(
        id: 'p1',
        authorId: 'u1',
        localityId: 'l1',
        content: 'Pothole on main road',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'INFRASTRUCTURE',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Pothole');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(service.searchCalls, equals(1));
    expect(service.lastQuery, equals('Pothole'));
    expect(find.text('Pothole on main road'), findsOneWidget);
  });

  testWidgets('renders empty results state', (tester) async {
    final service = FakePostsService();
    service.searchResults = [];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nonexistent');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('No posts found'), findsOneWidget);
  });

  testWidgets('renders error state and retries cleanly', (tester) async {
    final service = FakePostsService();
    service.shouldThrow = true;

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Road');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('Failed to search posts'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    service.shouldThrow = false;
    service.searchResults = [
      PostModel(
        id: 'p1',
        authorId: 'u1',
        localityId: 'l1',
        content: 'Road repaired',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Road repaired'), findsOneWidget);
  });
}
