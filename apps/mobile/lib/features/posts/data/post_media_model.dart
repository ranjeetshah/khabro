enum PostMediaType {
  image('IMAGE'),
  video('VIDEO'),
  unknown('UNKNOWN');

  const PostMediaType(this.wire);
  final String wire;

  static PostMediaType fromWire(String? value) {
    if (value == null) return PostMediaType.unknown;
    return PostMediaType.values.firstWhere(
      (e) => e.wire == value.toUpperCase(),
      orElse: () => PostMediaType.unknown,
    );
  }
}

enum MediaProvider {
  youtube('YOUTUBE'),
  khbroCdn('KHABRO_CDN'),
  unknown('UNKNOWN');

  const MediaProvider(this.wire);
  final String wire;

  static MediaProvider fromWire(String? value) {
    if (value == null) return MediaProvider.unknown;
    return MediaProvider.values.firstWhere(
      (e) => e.wire == value.toUpperCase(),
      orElse: () => MediaProvider.unknown,
    );
  }
}

enum MediaProcessingStatus {
  uploading('UPLOADING'),
  processing('PROCESSING'),
  ready('READY'),
  failed('FAILED'),
  unknown('UNKNOWN');

  const MediaProcessingStatus(this.wire);
  final String wire;

  static MediaProcessingStatus fromWire(String? value) {
    if (value == null) return MediaProcessingStatus.unknown;
    return MediaProcessingStatus.values.firstWhere(
      (e) => e.wire == value.toUpperCase(),
      orElse: () => MediaProcessingStatus.unknown,
    );
  }
}

class PostMediaModel {
  const PostMediaModel({
    required this.id,
    required this.type,
    required this.provider,
    required this.url,
    this.thumbnailUrl,
    this.providerMediaId,
    this.mimeType,
    this.width,
    this.height,
    this.durationSeconds,
    this.processingStatus = MediaProcessingStatus.ready,
    this.sortOrder = 0,
  });

  final String id;
  final PostMediaType type;
  final MediaProvider provider;
  final String url;
  final String? thumbnailUrl;
  final String? providerMediaId;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final MediaProcessingStatus processingStatus;
  final int sortOrder;

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    return PostMediaModel(
      id: json['id'] as String? ?? '',
      type: PostMediaType.fromWire(json['type'] as String?),
      provider: MediaProvider.fromWire(json['provider'] as String?),
      url: json['url'] as String? ?? json['mediaUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      providerMediaId: json['providerMediaId'] as String?,
      mimeType: json['mimeType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      processingStatus: MediaProcessingStatus.fromWire(
        json['processingStatus'] as String?,
      ),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.wire,
      'provider': provider.wire,
      'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (providerMediaId != null) 'providerMediaId': providerMediaId,
      if (mimeType != null) 'mimeType': mimeType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'processingStatus': processingStatus.wire,
      'sortOrder': sortOrder,
    };
  }
}
