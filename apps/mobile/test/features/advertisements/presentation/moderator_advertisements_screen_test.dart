import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/advertisements/data/advertisement_model.dart';
import 'package:mobile/features/advertisements/data/advertisement_service.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/moderator/presentation/moderator_advertisement_detail_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_advertisements_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_advertisement_form_screen.dart';

AdvertisementModel _ad([Map<String, dynamic>? overrides]) => AdvertisementModel(
  id: 'ad-1',
  title: 'Clean Water Drive',
  description: 'Join us this weekend.',
  advertiserName: 'CityWorks',
  creativeUrl: 'https://cdn.example.com/ad.png',
  destinationUrl: 'https://cityworks.example.com',
  ctaLabel: 'Donate',
  placement: AdvertisementPlacement.feed,
  status: AdvertisementStatus.draft,
  impressionCount: 10,
  clickCount: 1,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

class FakeAdvertisementService extends AdvertisementService {
  FakeAdvertisementService() : super(apiClient: null, tokenStorage: null);

  bool throw403 = false;
  bool throwError = false;
  bool throw401 = false;
  List<AdvertisementModel> ads = [_ad()];
  AdvertisementModel detail = _ad();
  String? activatedId;
  String? pausedId;
  String? cancelledId;
  Map<String, dynamic>? createdPayload;
  Map<String, dynamic>? updatedPayload;

  @override
  Future<AdvertisementPageModel> getModeratorAdvertisements({
    int page = 1,
    int limit = 20,
    String? status,
    String? placement,
  }) async {
    if (throw403) {
      throw const AuthException('Forbidden', statusCode: 403);
    }
    if (throwError) {
      throw const AuthException('Failed to load advertisements', statusCode: 500);
    }
    if (throw401) {
      throw const AuthException('Session expired', statusCode: 401);
    }
    return AdvertisementPageModel(
      items: ads,
      page: 1,
      limit: limit,
      total: ads.length,
      hasMore: false,
    );
  }

  @override
  Future<AdvertisementModel> getModeratorAdvertisementDetail(String id) async {
    if (throwError) {
      throw const AuthException('Failed to load advertisement', statusCode: 500);
    }
    return detail;
  }

  @override
  Future<AdvertisementModel> activateAdvertisement(String id) async {
    activatedId = id;
    detail = AdvertisementModel(
      id: detail.id,
      title: detail.title,
      description: detail.description,
      advertiserName: detail.advertiserName,
      creativeUrl: detail.creativeUrl,
      destinationUrl: detail.destinationUrl,
      ctaLabel: detail.ctaLabel,
      placement: detail.placement,
      status: AdvertisementStatus.active,
      startAt: detail.startAt,
      endAt: detail.endAt,
      impressionCount: detail.impressionCount,
      clickCount: detail.clickCount,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
    );
    return detail;
  }

  @override
  Future<AdvertisementModel> pauseAdvertisement(String id) async {
    pausedId = id;
    return detail;
  }

  @override
  Future<void> cancelAdvertisement(String id) async {
    cancelledId = id;
  }

  @override
  Future<AdvertisementModel> createAdvertisement(Map<String, dynamic> fields) async {
    createdPayload = fields;
    return _ad();
  }

  @override
  Future<AdvertisementModel> updateAdvertisement(
    String id,
    Map<String, dynamic> fields,
  ) async {
    updatedPayload = fields;
    return _ad(fields);
  }
}

void main() {
  testWidgets('lists advertisements with status and placement', (tester) async {
    final service = FakeAdvertisementService();
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorAdvertisementsScreen(advertisementService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clean Water Drive'), findsOneWidget);
    expect(find.text('CityWorks  \u2022  Feed'), findsOneWidget);
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('10 impressions \u2022 1 clicks \u2022 CTR 10.0%'), findsOneWidget);
  });

  testWidgets('handles 403 access denied', (tester) async {
    final service = FakeAdvertisementService()..throw403 = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorAdvertisementsScreen(advertisementService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Forbidden'), findsOneWidget);
  });

  testWidgets('detail screen shows metrics and pause/activate actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final service = FakeAdvertisementService();
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorAdvertisementDetailScreen(
          advertisementService: service,
          advertisementId: 'ad-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clean Water Drive'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Placement'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('10 impressions'), findsNothing);
    expect(find.text('10.00%'), findsOneWidget);

    await tester.tap(find.text('ACTIVATE'));
    await tester.pumpAndSettle();

    expect(service.activatedId, 'ad-1');
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
  });

  testWidgets('form screen validates required fields', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final service = FakeAdvertisementService();
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorAdvertisementFormScreen(
          advertisementService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE DRAFT'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Advertiser name is required'), findsOneWidget);
    expect(find.text('Creative image URL is required'), findsOneWidget);
    expect(find.text('Destination URL is required'), findsOneWidget);
  });

  testWidgets('form screen creates a draft with entered fields', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final service = FakeAdvertisementService();
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorAdvertisementFormScreen(
          advertisementService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Great Ad');
    await tester.enterText(find.byType(TextFormField).at(2), 'Advertiser Inc');
    await tester.enterText(find.byType(TextFormField).at(3), 'https://cdn.example.com/a.png');
    await tester.enterText(find.byType(TextFormField).at(4), 'https://example.com');
    await tester.tap(find.text('SAVE DRAFT'));
    await tester.pumpAndSettle();

    expect(service.createdPayload, isNotNull);
    expect(service.createdPayload!['title'], 'Great Ad');
    expect(service.createdPayload!['placement'], 'FEED');
  });
}