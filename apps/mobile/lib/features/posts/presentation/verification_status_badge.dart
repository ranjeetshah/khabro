import 'package:flutter/material.dart';

import '../data/verification_status.dart';

/// Human-readable label for a backend verification state.
///
/// Unknown/future statuses render the safe REPORTED label so the app never
/// claims a stronger meaning (e.g. "verified") the backend did not confirm.
String verificationStatusLabel(VerificationStatus status) {
  return switch (status) {
    VerificationStatus.reported => 'Reported locally',
    VerificationStatus.underVerification => 'Community verification in progress',
    VerificationStatus.locallyVerified => 'Locally verified',
    VerificationStatus.unknown => 'Reported locally',
  };
}

/// Compact verification badge for feed cards. Only non-REPORTED states render
/// anything to avoid cluttering the feed.
class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final VerificationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      VerificationStatus.locallyVerified => (
        Icons.verified_outlined,
        Colors.green,
      ),
      VerificationStatus.underVerification => (
        Icons.hourglass_top,
        Colors.orange,
      ),
      VerificationStatus.reported => (Icons.info_outline, Colors.blueGrey),
      VerificationStatus.unknown => (Icons.info_outline, Colors.blueGrey),
    };

    if (compact && (status.isReported || status.isUnknown)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              verificationStatusLabel(status),
              style: TextStyle(
                color: color,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
