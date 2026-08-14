import 'advertisement_model.dart';

/// Session-scoped, in-memory duplicate-impression guard.
///
/// A given advertisement may count at most once per session per placement.
/// Never persisted.
class ImpressionGuard {
  ImpressionGuard._();

  static final ImpressionGuard instance = ImpressionGuard._();

  final Set<String> _recorded = {};

  bool tryRecord(String adId, AdvertisementPlacement placement) {
    return _recorded.add('${placement.wire}:$adId');
  }
}