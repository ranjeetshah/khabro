import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/advertisements/data/advertisement_model.dart';

void main() {
  group('AdvertisementStatus', () {
    test('parses known wire values', () {
      expect(AdvertisementStatus.fromWire('DRAFT'), AdvertisementStatus.draft);
      expect(AdvertisementStatus.fromWire('ACTIVE'), AdvertisementStatus.active);
      expect(AdvertisementStatus.fromWire('PAUSED'), AdvertisementStatus.paused);
      expect(AdvertisementStatus.fromWire('EXPIRED'), AdvertisementStatus.expired);
    });

    test('falls back to unknown for unrecognized values', () {
      expect(AdvertisementStatus.fromWire('BOGUS'), AdvertisementStatus.unknown);
      expect(AdvertisementStatus.fromWire(null), AdvertisementStatus.unknown);
    });
  });

  group('AdvertisementPlacement', () {
    test('parses known wire values', () {
      expect(
        AdvertisementPlacement.fromWire('FEED'),
        AdvertisementPlacement.feed,
      );
      expect(
        AdvertisementPlacement.fromWire('POST_DETAIL'),
        AdvertisementPlacement.postDetail,
      );
      expect(
        AdvertisementPlacement.fromWire('PROFILE'),
        AdvertisementPlacement.profile,
      );
    });

    test('falls back to unknown for unrecognized values', () {
      expect(
        AdvertisementPlacement.fromWire('BOGUS'),
        AdvertisementPlacement.unknown,
      );
    });
  });

  group('AdvertisementModel', () {
    test('parses a full payload', () {
      final ad = AdvertisementModel.fromJson({
        'id': 'ad-1',
        'title': 'Clean Water Drive',
        'description': 'Join us this weekend.',
        'advertiserName': 'CityWorks',
        'creativeUrl': 'https://cdn.example.com/ad.png',
        'destinationUrl': 'https://cityworks.example.com/clean-water',
        'ctaLabel': 'Donate',
        'placement': 'FEED',
        'status': 'ACTIVE',
        'startAt': '2026-08-01T00:00:00.000Z',
        'endAt': '2026-09-01T00:00:00.000Z',
        'impressionCount': 100,
        'clickCount': 5,
        'createdAt': '2026-08-01T00:00:00.000Z',
        'updatedAt': '2026-08-01T00:00:00.000Z',
      });

      expect(ad.id, 'ad-1');
      expect(ad.title, 'Clean Water Drive');
      expect(ad.description, 'Join us this weekend.');
      expect(ad.advertiserName, 'CityWorks');
      expect(ad.creativeUrl, 'https://cdn.example.com/ad.png');
      expect(ad.destinationUrl, 'https://cityworks.example.com/clean-water');
      expect(ad.ctaLabel, 'Donate');
      expect(ad.placement, AdvertisementPlacement.feed);
      expect(ad.status, AdvertisementStatus.active);
      expect(ad.impressionCount, 100);
      expect(ad.clickCount, 5);
      expect(ad.ctr, 5.0);
    });

    test('handles missing and malformed fields without throwing', () {
      final ad = AdvertisementModel.fromJson(const {});

      expect(ad.id, '');
      expect(ad.title, '');
      expect(ad.placement, AdvertisementPlacement.unknown);
      expect(ad.status, AdvertisementStatus.unknown);
      expect(ad.impressionCount, 0);
      expect(ad.clickCount, 0);
      expect(ad.createdAt, isNotNull);
      expect(ad.updatedAt, isNotNull);
    });

    test('isEligibleForDisplay requires active status and valid window', () {
      final now = DateTime.now();
      final activeAd = AdvertisementModel(
        id: 'ad-1',
        title: 'T',
        advertiserName: 'A',
        creativeUrl: 'https://example.com/a.png',
        destinationUrl: 'https://example.com',
        placement: AdvertisementPlacement.feed,
        status: AdvertisementStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      expect(activeAd.isEligibleForDisplay, isTrue);

      final draft = AdvertisementModel(
        id: 'ad-1',
        title: 'T',
        advertiserName: 'A',
        creativeUrl: 'https://example.com/a.png',
        destinationUrl: 'https://example.com',
        placement: AdvertisementPlacement.feed,
        status: AdvertisementStatus.draft,
        createdAt: now,
        updatedAt: now,
      );
      expect(draft.isEligibleForDisplay, isFalse);

      final notStarted = AdvertisementModel(
        id: 'ad-1',
        title: 'T',
        advertiserName: 'A',
        creativeUrl: 'https://example.com/a.png',
        destinationUrl: 'https://example.com',
        placement: AdvertisementPlacement.feed,
        status: AdvertisementStatus.active,
        startAt: now.add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      );
      expect(notStarted.isEligibleForDisplay, isFalse);

      final expired = AdvertisementModel(
        id: 'ad-1',
        title: 'T',
        advertiserName: 'A',
        creativeUrl: 'https://example.com/a.png',
        destinationUrl: 'https://example.com',
        placement: AdvertisementPlacement.feed,
        status: AdvertisementStatus.active,
        endAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      );
      expect(expired.isEligibleForDisplay, isFalse);
    });
  });
}