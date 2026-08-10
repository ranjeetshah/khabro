import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/verification_status.dart';
import 'package:mobile/features/posts/data/verification_status_model.dart';

void main() {
  test('parses REPORTED with a zero witness count', () {
    final status = VerificationStatusModel.fromJson({
      'status': 'REPORTED',
      'witnessCount': 0,
    });
    expect(status.status, VerificationStatus.reported);
    expect(status.status.isReported, isTrue);
    expect(status.witnessCount, 0);
  });

  test('parses UNDER_VERIFICATION', () {
    final status = VerificationStatusModel.fromJson({
      'status': 'UNDER_VERIFICATION',
      'witnessCount': 1,
    });
    expect(status.status, VerificationStatus.underVerification);
    expect(status.status.isUnderVerification, isTrue);
    expect(status.witnessCount, 1);
  });

  test('parses LOCALLY_VERIFIED', () {
    final status = VerificationStatusModel.fromJson({
      'status': 'LOCALLY_VERIFIED',
      'witnessCount': 2,
    });
    expect(status.status, VerificationStatus.locallyVerified);
    expect(status.status.isLocallyVerified, isTrue);
    expect(status.witnessCount, 2);
  });

  test('unknown future statuses fall back without crashing', () {
    final status = VerificationStatusModel.fromJson({
      'status': 'AUTHORITY_CONFIRMED',
      'witnessCount': 5,
    });
    expect(status.status, VerificationStatus.unknown);
    expect(status.status.isUnknown, isTrue);
    expect(status.witnessCount, 5);
  });

  test('missing fields are parsed defensively', () {
    final status = VerificationStatusModel.fromJson({});
    expect(status.status, VerificationStatus.unknown);
    expect(status.witnessCount, 0);
  });

  test('verification status labels never overstate community meaning', () {
    expect(VerificationStatus.reported.wire, 'REPORTED');
    expect(VerificationStatus.underVerification.wire, 'UNDER_VERIFICATION');
    expect(VerificationStatus.locallyVerified.wire, 'LOCALLY_VERIFIED');
    expect(VerificationStatus.unknown.wire, 'UNKNOWN');
  });
}
