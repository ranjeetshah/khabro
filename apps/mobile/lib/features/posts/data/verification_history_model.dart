import 'verification_event.dart';
import 'verification_status.dart';

/// One privacy-safe verification history entry returned by
/// GET /posts/:id/verification/history.
///
/// Only event metadata is modeled — never witness identities, phone,
/// locality, or coordinates. Unknown types/statuses parse safely.
class VerificationEventModel {
  const VerificationEventModel({
    required this.type,
    required this.createdAt,
    this.fromStatus,
    this.toStatus,
  });

  final VerificationEventType type;
  final VerificationStatus? fromStatus;
  final VerificationStatus? toStatus;
  final DateTime createdAt;

  factory VerificationEventModel.fromJson(Map<String, dynamic> json) {
    return VerificationEventModel(
      type: VerificationEventType.fromWire(json['type'] as String?),
      fromStatus: json['fromStatus'] == null
          ? null
          : VerificationStatus.fromWire(json['fromStatus'] as String?),
      toStatus: json['toStatus'] == null
          ? null
          : VerificationStatus.fromWire(json['toStatus'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.wire,
      if (fromStatus != null) 'fromStatus': fromStatus!.wire,
      if (toStatus != null) 'toStatus': toStatus!.wire,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// The verification history payload for a post, ordered oldest-first by the
/// backend.
class VerificationHistoryModel {
  const VerificationHistoryModel({required this.events});

  final List<VerificationEventModel> events;

  factory VerificationHistoryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['events'];
    return VerificationHistoryModel(
      events: raw is List
          ? raw
                .map(
                  (event) => VerificationEventModel.fromJson(
                    event as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const <VerificationEventModel>[],
    );
  }
}
