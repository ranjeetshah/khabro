/// Complaint lifecycle statuses. Wire values match the backend ComplaintStatus
/// enum; labels are citizen-facing and neutral (no fabricated authority
/// wording). Unknown future statuses fall back to a safe placeholder.
enum ComplaintStatus {
  submitted('SUBMITTED', 'Submitted'),
  acknowledged('ACKNOWLEDGED', 'Acknowledged'),
  inProgress('IN_PROGRESS', 'In progress'),
  resolved('RESOLVED', 'Resolved'),
  citizenConfirmed('CITIZEN_CONFIRMED', 'Citizen confirmed'),
  reopened('REOPENED', 'Reopened'),
  unknown('UNKNOWN', 'Status update');

  const ComplaintStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ComplaintStatus fromWire(String? wire) {
    return ComplaintStatus.values.firstWhere(
      (status) => status.wire == wire,
      orElse: () => ComplaintStatus.unknown,
    );
  }
}
