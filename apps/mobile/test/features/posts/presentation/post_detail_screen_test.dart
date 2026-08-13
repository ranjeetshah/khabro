import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/complaints/data/complaint_model.dart';
import 'package:mobile/features/complaints/data/complaint_service.dart';
import 'package:mobile/features/complaints/data/complaint_status.dart';
import 'package:mobile/features/complaints/presentation/create_complaint_screen.dart';
import 'package:mobile/features/posts/data/comment_model.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/data/like_status_model.dart';
import 'package:mobile/features/posts/data/verification_status.dart';
import 'package:mobile/features/posts/data/verification_status_model.dart';
import 'package:mobile/features/posts/data/witness_status_model.dart';
import 'package:mobile/features/posts/data/verification_event.dart';
import 'package:mobile/features/posts/data/verification_history_model.dart';
import 'package:mobile/features/posts/data/civic_complaint_model.dart';
import 'package:mobile/features/posts/presentation/post_detail_screen.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';

PostModel detailPost({
  String? name = 'Test User',
  VerificationStatus verificationStatus = VerificationStatus.reported,
}) => PostModel(
  id: 'post-1',
  authorId: 'private-author-id',
  localityId: 'private-locality-id',
  content: 'Hello Khabro!',
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: PublicUserModel(id: 'author-1', name: name),
  verificationStatus: verificationStatus,
);

class FakePublicUserService extends PublicUserService {
  FakePublicUserService({this.user, this.error})
    : super(apiClient: null, tokenStorage: null);

  final PublicUserModel? user;
  final AuthException? error;
  var calls = 0;

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    calls++;
    if (error != null) throw error!;
    return user!;
  }
}

class FakeDeletePostsService extends PostsService {
  FakeDeletePostsService({
    this.errors = const [],
    this.verificationStatus = VerificationStatus.reported,
    this.history,
    this.historyError,
    this.historyCompleter,
    this.reportError,
    this.reportCompleter,
  }) : super(apiClient: null, tokenStorage: null);

  final List<Object> errors;
  VerificationStatus verificationStatus;
  var calls = 0;
  String? deletedId;
  var likeCalls = 0;
  var unlikeCalls = 0;
  var witnessCalls = 0;
  var unwitnessCalls = 0;
  var verificationCalls = 0;
  var historyCalls = 0;
  VerificationHistoryModel? history;
  Object? historyError;
  Completer<VerificationHistoryModel>? historyCompleter;
  var reportCalls = 0;
  String? reportId;
  String? reportReason;
  String? reportDescription;
  Object? reportError;
  Completer<void>? reportCompleter;

  @override
  Future<void> deletePost(String id) async {
    calls++;
    deletedId = id;
    if (calls <= errors.length) throw errors[calls - 1];
  }

  @override
  Future<void> reportPost(
    String id, {
    required String reason,
    String? description,
  }) async {
    reportCalls++;
    reportId = id;
    reportReason = reason;
    reportDescription = description;
    if (reportCompleter != null) return reportCompleter!.future;
    if (reportError != null) throw reportError!;
  }

  @override
  Future<LikeStatusModel> likePost(String id) async {
    likeCalls++;
    return const LikeStatusModel(likeCount: 1, likedByMe: true);
  }

  @override
  Future<LikeStatusModel> unlikePost(String id) async {
    unlikeCalls++;
    return const LikeStatusModel(likeCount: 0, likedByMe: false);
  }

  @override
  Future<WitnessStatusModel> witnessPost(String id) async {
    witnessCalls++;
    return const WitnessStatusModel(witnessCount: 1, witnessedByMe: true);
  }

  @override
  Future<WitnessStatusModel> unwitnessPost(String id) async {
    unwitnessCalls++;
    return const WitnessStatusModel(witnessCount: 0, witnessedByMe: false);
  }

  @override
  Future<VerificationStatusModel> getVerificationStatus(String id) async {
    verificationCalls++;
    return VerificationStatusModel(
      status: verificationStatus,
      witnessCount: 0,
    );
  }

  CivicComplaintModel? civicComplaint;
  var confirmCalls = 0;
  var reopenCalls = 0;
  String? reopenReason;

  @override
  Future<CivicComplaintModel?> getCivicComplaint(String id) async {
    return civicComplaint;
  }

  @override
  Future<CivicComplaintModel> confirmCivicComplaintResolution(String id) async {
    confirmCalls++;
    return CivicComplaintModel(
      referenceCode: civicComplaint?.referenceCode ?? 'KH-2026-000123',
      status: 'CITIZEN_CONFIRMED',
      witnessCount: 20,
    );
  }

  @override
  Future<CivicComplaintModel> reopenCivicComplaint(String id, String reason) async {
    reopenCalls++;
    reopenReason = reason;
    return CivicComplaintModel(
      referenceCode: civicComplaint?.referenceCode ?? 'KH-2026-000123',
      status: 'REOPENED',
      witnessCount: 20,
    );
  }

  @override
  Future<VerificationHistoryModel> getVerificationHistory(String id) async {
    historyCalls++;
    if (historyCompleter != null) return historyCompleter!.future;
    if (historyError != null) throw historyError!;
    return history ?? const VerificationHistoryModel(events: []);
  }

  @override
  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async => [];

  @override
  Future<CommentModel> createReply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    return CommentModel(
      id: 'reply-1',
      content: content,
      createdAt: DateTime.now(),
      authorId: 'user-1',
      authorName: 'Test Reply Author',
      parentId: commentId,
    );
  }

  @override
  Future<List<CommentModel>> getCommentReplies({
    required String postId,
    required String commentId,
    int page = 1,
    int limit = 20,
  }) async => [];
}

class FakeComplaintService extends ComplaintService {
  FakeComplaintService() : super(apiClient: null, tokenStorage: null);
  var createCalls = 0;
  String? createPostId;
  String? createDescription;

  @override
  Future<ComplaintSubmissionModel> createComplaint(
    String postId,
    String description,
  ) async {
    createCalls++;
    createPostId = postId;
    createDescription = description;
    return ComplaintSubmissionModel(
      id: 'complaint-1',
      status: ComplaintStatus.submitted,
    );
  }
}

void main() {
  testWidgets('renders safe post detail fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PostDetailScreen(post: detailPost())),
    );

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
    expect(find.textContaining('2026-08-09'), findsOneWidget);
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('private-locality-id'), findsNothing);
  });

  testWidgets(
    'author tap opens the public profile and back returns to detail',
    (tester) async {
      final service = FakePublicUserService(
        user: const PublicUserModel(id: 'author-1', name: 'Test User'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            post: detailPost(),
            publicUserService: service,
            postsService: FakeDeletePostsService(),
          ),
        ),
      );

      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicAuthorProfileScreen), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(service.calls, 1);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Hello Khabro!'), findsOneWidget);
    },
  );

  testWidgets('uses the safe fallback when author name is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(name: '')),
      ),
    );
    expect(find.text('Khabro User'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
  });

  testWidgets('only the owner sees delete and cancel makes no request', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    expect(find.byTooltip('Delete post'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    expect(find.text('Delete post?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.text('Hello Khabro!'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'different-user',
          postsService: service,
        ),
      ),
    );
    expect(find.byTooltip('Delete post'), findsNothing);
  });

  testWidgets('confirming delete calls the service and closes detail', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.deletedId, 'post-1');
    expect(find.text('Hello Khabro!'), findsNothing);
  });

  testWidgets('delete errors are safe and retry works', (tester) async {
    final service = FakeDeletePostsService(
      errors: [
        const AuthException('Forbidden', statusCode: 403),
        const AuthException('Not found', statusCode: 404),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('You can only delete your own posts.'), findsOneWidget);
    expect(find.text('private-author-id'), findsNothing);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text('Post not found.'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('like and unlike work without leaving post detail', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();
    expect(service.likeCalls, 1);
    expect(find.text('1'), findsOneWidget);
    expect(find.byTooltip('Unlike'), findsOneWidget);
    await tester.tap(find.byTooltip('Unlike'));
    await tester.pumpAndSettle();
    expect(service.unlikeCalls, 1);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('witness action updates state and count', (tester) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          postsService: service,
        ),
      ),
    );
    expect(find.text('I Witnessed This'), findsOneWidget);
    expect(find.text('Witnesses: 0'), findsOneWidget);
    await tester.tap(find.text('I Witnessed This'));
    await tester.pumpAndSettle();
    expect(service.witnessCalls, 1);
    expect(find.text('Witnessed'), findsOneWidget);
    expect(find.text('Witnesses: 1'), findsOneWidget);
    await tester.tap(find.text('Witnessed'));
    await tester.pumpAndSettle();
    expect(service.unwitnessCalls, 1);
    expect(find.text('I Witnessed This'), findsOneWidget);
  });

  testWidgets('handles session expiry and network failures safely', (
    tester,
  ) async {
    var sessionExpired = false;
    final service = FakeDeletePostsService(
      errors: [
        const AuthException('Unauthorized', statusCode: 401),
        Exception('network failure'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
          onSessionExpired: () => sessionExpired = true,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(sessionExpired, isTrue);
    expect(find.text("Couldn't delete this post."), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't delete this post."), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('REPORTED post shows the reported locally label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          postsService: FakeDeletePostsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reported locally'), findsOneWidget);
    expect(find.text('Locally verified'), findsNothing);
    expect(find.text('Community verification in progress'), findsNothing);
  });

  testWidgets('UNDER_VERIFICATION post shows verification in progress', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.underVerification,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community verification in progress'), findsOneWidget);
    expect(find.text('Reported locally'), findsNothing);
    expect(find.text('Locally verified'), findsNothing);
    expect(service.verificationCalls, 1);
  });

  testWidgets('LOCALLY_VERIFIED post shows the locally verified label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: FakeDeletePostsService(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Locally verified'), findsOneWidget);
    expect(find.text('Reported locally'), findsNothing);
    expect(find.text('Community verification in progress'), findsNothing);
    expect(find.text('True'), findsNothing);
    expect(find.text('Confirmed'), findsNothing);
    expect(find.text('Officially verified'), findsNothing);
    expect(find.text('Government verified'), findsNothing);
  });

  testWidgets('unknown future status falls back to the reported label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.unknown,
          ),
          postsService: FakeDeletePostsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reported locally'), findsOneWidget);
    expect(find.text('Locally verified'), findsNothing);
  });

  testWidgets('verification section never exposes private metadata', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('private-locality-id'), findsNothing);
    expect(find.text('author-1'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('JWT'), findsNothing);
  });

  testWidgets('verification history loads and shows events oldest-first', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      history: VerificationHistoryModel(
        events: [
          VerificationEventModel(
            type: VerificationEventType.postCreated,
            toStatus: VerificationStatus.reported,
            createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
          ),
          VerificationEventModel(
            type: VerificationEventType.witnessAdded,
            createdAt: DateTime.parse('2026-08-09T09:00:00.000Z'),
          ),
          VerificationEventModel(
            type: VerificationEventType.statusChanged,
            fromStatus: VerificationStatus.reported,
            toStatus: VerificationStatus.underVerification,
            createdAt: DateTime.parse('2026-08-09T10:00:00.000Z'),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.historyCalls, 1);
    expect(find.text('Verification history'), findsOneWidget);
    expect(find.text('Post reported locally'), findsOneWidget);
    expect(find.text('A community member witnessed this'), findsOneWidget);
    expect(
      find.text('Verification status changed to Under verification'),
      findsOneWidget,
    );

    final firstY = tester.getTopLeft(find.text('Post reported locally')).dy;
    final lastY = tester
        .getTopLeft(
          find.text('Verification status changed to Under verification'),
        )
        .dy;
    expect(firstY, lessThan(lastY));
  });

  testWidgets('verification history shows a loading indicator first', (
    tester,
  ) async {
    final completer = Completer<VerificationHistoryModel>();
    final service = FakeDeletePostsService(historyCompleter: completer);
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const VerificationHistoryModel(events: []));
    await tester.pumpAndSettle();
    expect(find.text('No verification activity yet.'), findsOneWidget);
  });

  testWidgets('verification history shows an empty state', (tester) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification history'), findsOneWidget);
    expect(find.text('No verification activity yet.'), findsOneWidget);
  });

  testWidgets('verification history errors show a retry that recovers', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      historyError: const AuthException('Unavailable', statusCode: 500),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load verification history."), findsOneWidget);

    service.historyError = null;
    service.history = VerificationHistoryModel(
      events: [
        VerificationEventModel(
          type: VerificationEventType.witnessAdded,
          createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
        ),
      ],
    );
    await tester.tap(find.text('RETRY HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load verification history."), findsNothing);
    expect(find.text('A community member witnessed this'), findsOneWidget);
  });

  testWidgets('unknown history event types render a safe fallback', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      history: VerificationHistoryModel(
        events: [
          VerificationEventModel(
            type: VerificationEventType.unknown,
            createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification activity'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('history never exposes witness identities or coordinates', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      history: VerificationHistoryModel(
        events: [
          VerificationEventModel(
            type: VerificationEventType.witnessAdded,
            createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
          ),
          VerificationEventModel(
            type: VerificationEventType.statusChanged,
            fromStatus: VerificationStatus.reported,
            toStatus: VerificationStatus.underVerification,
            createdAt: DateTime.parse('2026-08-09T09:00:00.000Z'),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('user-1'), findsNothing);
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('private-locality-id'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('JWT'), findsNothing);
  });

  testWidgets('history stays visible while witness actions still work', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      history: VerificationHistoryModel(
        events: [
          VerificationEventModel(
            type: VerificationEventType.postCreated,
            toStatus: VerificationStatus.reported,
            createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Post reported locally'), findsOneWidget);

    await tester.tap(find.text('I Witnessed This'));
    await tester.pumpAndSettle();
    expect(service.witnessCalls, 1);
    expect(find.text('Witnessed'), findsOneWidget);
    expect(find.text('Post reported locally'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets(
    'report flow requires a reason and submits the wire reason safely',
    (tester) async {
      final service = FakeDeletePostsService();
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: detailPost(), postsService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report post'));
      await tester.pumpAndSettle();
      expect(find.text('Why are you reporting this?'), findsOneWidget);

      final submit = find.widgetWithText(FilledButton, 'Submit report');
      expect(submit, findsOneWidget);
      await tester.tap(submit);
      await tester.pump();
      expect(service.reportCalls, 0);

      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).last,
        'Repeated low-quality posts',
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(service.reportCalls, 1);
      expect(service.reportId, 'post-1');
      expect(service.reportReason, 'SPAM');
      expect(service.reportDescription, 'Repeated low-quality posts');
      expect(find.text('Report submitted'), findsOneWidget);
      expect(find.text('complaint-1'), findsNothing);
      expect(find.text('JWT'), findsNothing);
      expect(find.text('private-locality-id'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Hello Khabro!'), findsOneWidget);
    },
  );

  testWidgets(
    'report errors show a retry path that recovers',
    (tester) async {
      final service = FakeDeletePostsService(reportError: Exception('boom'));
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: detailPost(), postsService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
      await tester.pumpAndSettle();
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(service.reportCalls, 1);

      service.reportError = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
      await tester.pumpAndSettle();
      expect(service.reportCalls, 2);
      expect(find.text('Report submitted'), findsOneWidget);
    },
  );

  testWidgets('report dialog ignores duplicate taps while in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    final service = FakeDeletePostsService(reportCompleter: completer);
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harassment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(service.reportCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('complaint button shows only for locally verified posts', (
    tester,
  ) async {
    for (final status in [
      VerificationStatus.reported,
      VerificationStatus.underVerification,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            key: ValueKey('status-${status.name}'),
            post: detailPost(verificationStatus: status),
            postsService: FakeDeletePostsService(verificationStatus: status),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Submit Civic Complaint'), findsNothing);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          key: const ValueKey('status-locallyVerified'),
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: FakeDeletePostsService(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Submit Civic Complaint'), findsOneWidget);
  });

  testWidgets('submit complaint opens the create complaint screen', (
    tester,
  ) async {
    final complaintService = FakeComplaintService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: FakeDeletePostsService(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          complaintService: complaintService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Civic Complaint'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateComplaintScreen), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('displays SENT civic complaint status and reference code', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    service.civicComplaint = const CivicComplaintModel(
      referenceCode: 'KH-2026-000123',
      status: 'SENT',
      witnessCount: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community Complaint'), findsOneWidget);
    expect(
      find.text('Complaint sent to the concerned authority.'),
      findsOneWidget,
    );
    expect(find.text('Reference: KH-2026-000123'), findsOneWidget);
  });

  testWidgets('displays FAILED civic complaint status safely', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    service.civicComplaint = const CivicComplaintModel(
      referenceCode: 'KH-2026-000123',
      status: 'FAILED',
      witnessCount: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community Complaint'), findsOneWidget);
    expect(find.text('Complaint could not be sent.'), findsOneWidget);
  });

  testWidgets('displays RESOLVED civic complaint status with action buttons', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    service.civicComplaint = const CivicComplaintModel(
      referenceCode: 'KH-2026-000123',
      status: 'RESOLVED',
      witnessCount: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community Complaint'), findsOneWidget);
    expect(
      find.text('Has this issue actually been resolved?'),
      findsOneWidget,
    );
    expect(find.text('Confirm Resolution'), findsOneWidget);
    expect(find.text('Reopen Complaint'), findsOneWidget);

    await tester.tap(find.text('Confirm Resolution'));
    await tester.pumpAndSettle();

    expect(service.confirmCalls, equals(1));
    expect(find.text('Resolution confirmed by community.'), findsOneWidget);
  });

  testWidgets('reopens RESOLVED civic complaint with reason dialog', (
    tester,
  ) async {
    final service = FakeDeletePostsService(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    service.civicComplaint = const CivicComplaintModel(
      referenceCode: 'KH-2026-000123',
      status: 'RESOLVED',
      witnessCount: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(
            verificationStatus: VerificationStatus.locallyVerified,
          ),
          postsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reopen Complaint'));
    await tester.pumpAndSettle();

    expect(find.text('Reopen Complaint'), findsWidgets);
    expect(find.text('Reason for reopening'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'The road is still blocked.',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(service.reopenCalls, equals(1));
    expect(service.reopenReason, equals('The road is still blocked.'));
    expect(find.text('Complaint reopened.'), findsOneWidget);
  });
}
