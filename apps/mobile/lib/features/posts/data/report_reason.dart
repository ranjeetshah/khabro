/// Moderation reasons a reporter can select. Wire values match the backend
/// PostReportReason enum; labels are user-facing and never reveal reporter
/// or internal moderation details.
enum ReportReason {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Harassment'),
  falseInformation('FALSE_INFORMATION', 'False information'),
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Inappropriate content'),
  dangerousContent('DANGEROUS_CONTENT', 'Dangerous content'),
  other('OTHER', 'Other');

  const ReportReason(this.wire, this.label);

  final String wire;
  final String label;
}
