enum AdvertisementPlacement {
  feed,
  postDetail,
  profile,
  unknown;

  static AdvertisementPlacement fromWire(String? value) {
    switch (value) {
      case 'FEED':
        return AdvertisementPlacement.feed;
      case 'POST_DETAIL':
        return AdvertisementPlacement.postDetail;
      case 'PROFILE':
        return AdvertisementPlacement.profile;
      default:
        return AdvertisementPlacement.unknown;
    }
  }

  String get wire {
    switch (this) {
      case AdvertisementPlacement.feed:
        return 'FEED';
      case AdvertisementPlacement.postDetail:
        return 'POST_DETAIL';
      case AdvertisementPlacement.profile:
        return 'PROFILE';
      case AdvertisementPlacement.unknown:
        return 'FEED';
    }
  }

  String get label {
    switch (this) {
      case AdvertisementPlacement.feed:
        return 'Feed';
      case AdvertisementPlacement.postDetail:
        return 'Post Detail';
      case AdvertisementPlacement.profile:
        return 'Profile';
      case AdvertisementPlacement.unknown:
        return 'Feed';
    }
  }
}

enum AdvertisementStatus {
  draft,
  active,
  paused,
  expired,
  unknown;

  static AdvertisementStatus fromWire(String? value) {
    switch (value) {
      case 'DRAFT':
        return AdvertisementStatus.draft;
      case 'ACTIVE':
        return AdvertisementStatus.active;
      case 'PAUSED':
        return AdvertisementStatus.paused;
      case 'EXPIRED':
        return AdvertisementStatus.expired;
      default:
        return AdvertisementStatus.unknown;
    }
  }

  String get wire {
    switch (this) {
      case AdvertisementStatus.draft:
        return 'DRAFT';
      case AdvertisementStatus.active:
        return 'ACTIVE';
      case AdvertisementStatus.paused:
        return 'PAUSED';
      case AdvertisementStatus.expired:
        return 'EXPIRED';
      case AdvertisementStatus.unknown:
        return 'DRAFT';
    }
  }

  String get label {
    switch (this) {
      case AdvertisementStatus.draft:
        return 'Draft';
      case AdvertisementStatus.active:
        return 'Active';
      case AdvertisementStatus.paused:
        return 'Paused';
      case AdvertisementStatus.expired:
        return 'Expired';
      case AdvertisementStatus.unknown:
        return 'Unknown';
    }
  }
}

class AdvertisementModel {
  const AdvertisementModel({
    required this.id,
    required this.title,
    this.description,
    required this.advertiserName,
    required this.creativeUrl,
    required this.destinationUrl,
    this.ctaLabel,
    required this.placement,
    required this.status,
    this.startAt,
    this.endAt,
    this.impressionCount = 0,
    this.clickCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String advertiserName;
  final String creativeUrl;
  final String destinationUrl;
  final String? ctaLabel;
  final AdvertisementPlacement placement;
  final AdvertisementStatus status;
  final DateTime? startAt;
  final DateTime? endAt;
  final int impressionCount;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      advertiserName: json['advertiserName'] as String? ?? '',
      creativeUrl: json['creativeUrl'] as String? ?? '',
      destinationUrl: json['destinationUrl'] as String? ?? '',
      ctaLabel: json['ctaLabel'] as String?,
      placement: AdvertisementPlacement.fromWire(json['placement'] as String?),
      status: AdvertisementStatus.fromWire(json['status'] as String?),
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
      impressionCount: _parseCount(json['impressionCount']),
      clickCount: _parseCount(json['clickCount']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static int _parseCount(Object? value) {
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'advertiserName': advertiserName,
    'creativeUrl': creativeUrl,
    'destinationUrl': destinationUrl,
    'ctaLabel': ctaLabel,
    'placement': placement.wire,
    'status': status.wire,
    'startAt': startAt?.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'impressionCount': impressionCount,
    'clickCount': clickCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool get isEligibleForDisplay {
    if (status != AdvertisementStatus.active) return false;
    final now = DateTime.now();
    if (startAt != null && startAt!.isAfter(now)) return false;
    if (endAt != null && endAt!.isBefore(now)) return false;
    return true;
  }

  double get ctr {
    if (impressionCount <= 0) return 0;
    return (clickCount / impressionCount) * 100;
  }
}