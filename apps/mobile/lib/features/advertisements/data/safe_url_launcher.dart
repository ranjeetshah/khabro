import 'package:url_launcher/url_launcher.dart';

/// Guards against opening non-https or non-loopback URLs.
bool isSafeExternalUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https') return true;
  if (scheme == 'http') {
    final host = uri.host.toLowerCase();
    if (host == '::1') return true;
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0';
  }
  return false;
}

typedef UrlOpener = Future<bool> Function(String url);

/// Opens a destination URL only after a safety check.
Future<bool> openAdvertisementUrl(String url, {UrlOpener? opener}) async {
  if (!isSafeExternalUrl(url)) return false;
  final launch = opener ?? _launch;
  return launch(url);
}

Future<bool> _launch(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}