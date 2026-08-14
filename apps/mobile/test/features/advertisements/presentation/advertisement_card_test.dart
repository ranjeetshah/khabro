import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/advertisements/data/advertisement_model.dart';
import 'package:mobile/features/advertisements/data/impression_guard.dart';
import 'package:mobile/features/advertisements/presentation/advertisement_card.dart';

AdvertisementModel _ad() => AdvertisementModel(
  id: 'ad-1',
  title: 'Clean Water Drive',
  description: 'Join us this weekend.',
  advertiserName: 'CityWorks',
  creativeUrl: 'https://cdn.example.com/ad.png',
  destinationUrl: 'https://cityworks.example.com',
  ctaLabel: 'Donate',
  placement: AdvertisementPlacement.feed,
  status: AdvertisementStatus.active,
  impressionCount: 10,
  clickCount: 1,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

void main() {
  setUp(() {
    ImpressionGuard.instance.tryRecord(
      'ad-1',
      AdvertisementPlacement.feed,
    );
  });

  testWidgets('renders sponsored label, title and advertiser', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvertisementCard(
            advertisement: _ad(),
            onImpression: (_) async {},
            onClick: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.text('Clean Water Drive'), findsOneWidget);
    expect(find.text('CityWorks'), findsOneWidget);
    expect(find.text('Donate'), findsOneWidget);
  });

  testWidgets('compact mode hides the image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvertisementCard(
            advertisement: _ad(),
            onImpression: (_) async {},
            onClick: (_) async {},
            compact: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows an error message when the destination fails to open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvertisementCard(
            advertisement: _ad(),
            onImpression: (_) async {},
            onClick: (_) async {},
            urlOpener: (url) async => false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(AdvertisementCard));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t open this advertisement.'), findsOneWidget);
  });
}