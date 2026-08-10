/// Backend-owned verification event types for a post.
///
/// Only events the backend emits are modeled. [unknown] is a defensive
/// fallback for future/unknown event types so parsing never crashes and the
/// app can keep showing the history without fabricating meaning.
enum VerificationEventType {
  postCreated,
  witnessAdded,
  witnessRemoved,
  statusChanged,
  unknown;

  factory VerificationEventType.fromWire(String? value) {
    return switch (value) {
      'POST_CREATED' => VerificationEventType.postCreated,
      'WITNESS_ADDED' => VerificationEventType.witnessAdded,
      'WITNESS_REMOVED' => VerificationEventType.witnessRemoved,
      'STATUS_CHANGED' => VerificationEventType.statusChanged,
      _ => VerificationEventType.unknown,
    };
  }

  String get wire => switch (this) {
    VerificationEventType.postCreated => 'POST_CREATED',
    VerificationEventType.witnessAdded => 'WITNESS_ADDED',
    VerificationEventType.witnessRemoved => 'WITNESS_REMOVED',
    VerificationEventType.statusChanged => 'STATUS_CHANGED',
    VerificationEventType.unknown => 'UNKNOWN',
  };

  bool get isPostCreated => this == VerificationEventType.postCreated;
  bool get isWitnessAdded => this == VerificationEventType.witnessAdded;
  bool get isWitnessRemoved => this == VerificationEventType.witnessRemoved;
  bool get isStatusChanged => this == VerificationEventType.statusChanged;
  bool get isUnknown => this == VerificationEventType.unknown;
}
