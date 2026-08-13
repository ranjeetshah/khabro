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
    if (compact && (status.isReported || status.isUnknown)) {
      return const SizedBox.shrink();
    }

    final (icon, color, bgColor) = switch (status) {
      VerificationStatus.locallyVerified => (
        Icons.check_circle_outline,
        Colors.green.shade700,
        Colors.green.shade50,
      ),
      VerificationStatus.underVerification => (
        Icons.hourglass_empty,
        Colors.amber.shade800,
        Colors.amber.shade50,
      ),
      VerificationStatus.reported => (
        Icons.info_outline,
        Colors.grey.shade700,
        Colors.grey.shade100,
      ),
      VerificationStatus.unknown => (
        Icons.info_outline,
        Colors.grey.shade700,
        Colors.grey.shade100,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              verificationStatusLabel(status),
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
