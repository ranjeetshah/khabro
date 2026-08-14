import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/advertisements/data/safe_url_launcher.dart';

void main() {
  group('isSafeExternalUrl', () {
    test('accepts https URLs', () {
      expect(isSafeExternalUrl('https://example.com'), isTrue);
      expect(isSafeExternalUrl('https://example.com/path?q=1'), isTrue);
    });

    test('accepts http only on loopback hosts', () {
      expect(isSafeExternalUrl('http://localhost:3000'), isTrue);
      expect(isSafeExternalUrl('http://127.0.0.1:3000/ads'), isTrue);
      expect(isSafeExternalUrl('http://0.0.0.0:3000'), isTrue);
      expect(isSafeExternalUrl('http://[::1]:3000'), isTrue);
    });

    test('rejects http on non-loopback hosts', () {
      expect(isSafeExternalUrl('http://example.com'), isFalse);
      expect(isSafeExternalUrl('http://evil.com'), isFalse);
    });

    test('rejects dangerous schemes and malformed urls', () {
      expect(isSafeExternalUrl('javascript:alert(1)'), isFalse);
      expect(isSafeExternalUrl('data:text/html;base64,abc'), isFalse);
      expect(isSafeExternalUrl('file:///etc/passwd'), isFalse);
      expect(isSafeExternalUrl('intent://example.com'), isFalse);
      expect(isSafeExternalUrl('ftp://example.com'), isFalse);
      expect(isSafeExternalUrl(''), isFalse);
      expect(isSafeExternalUrl('not a url'), isFalse);
    });
  });

  group('openAdvertisementUrl', () {
    test('does not open unsafe urls and returns false', () async {
      var opened = '';
      final result = await openAdvertisementUrl('javascript:alert(1)', opener: (url) async {
        opened = url;
        return true;
      });
      expect(result, isFalse);
      expect(opened, isEmpty);
    });

    test('opens safe urls via the provided opener', () async {
      String? openedUrl;
      final result = await openAdvertisementUrl(
        'https://cityworks.example.com',
        opener: (url) async {
          openedUrl = url;
          return true;
        },
      );
      expect(result, isTrue);
      expect(openedUrl, 'https://cityworks.example.com');
    });

    test('propagates a failing opener as false', () async {
      final result = await openAdvertisementUrl(
        'https://cityworks.example.com',
        opener: (url) async => false,
      );
      expect(result, isFalse);
    });
  });
}