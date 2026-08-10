/// Backend-owned verification states for a post.
///
/// The backend is the source of truth for verification. The app never
/// calculates verification state from witness counts; it only displays the
/// status returned by the server. [unknown] is a defensive fallback for
/// future/unknown backend statuses so parsing never crashes.
enum VerificationStatus {
  reported,
  underVerification,
  locallyVerified,
  unknown;

  factory VerificationStatus.fromWire(String? value) {
    return switch (value) {
      'REPORTED' => VerificationStatus.reported,
      'UNDER_VERIFICATION' => VerificationStatus.underVerification,
      'LOCALLY_VERIFIED' => VerificationStatus.locallyVerified,
      _ => VerificationStatus.unknown,
    };
  }

  String get wire => switch (this) {
    VerificationStatus.reported => 'REPORTED',
    VerificationStatus.underVerification => 'UNDER_VERIFICATION',
    VerificationStatus.locallyVerified => 'LOCALLY_VERIFIED',
    VerificationStatus.unknown => 'UNKNOWN',
  };

  bool get isReported => this == VerificationStatus.reported;
  bool get isUnderVerification =>
      this == VerificationStatus.underVerification;
  bool get isLocallyVerified => this == VerificationStatus.locallyVerified;
  bool get isUnknown => this == VerificationStatus.unknown;
}
