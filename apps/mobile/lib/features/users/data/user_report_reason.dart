/// User moderation reasons a reporter can select. Wire values match the backend
/// UserReportReason enum.
enum UserReportReason {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Harassment'),
  impersonation('IMPERSONATION', 'Impersonation'),
  abusiveBehavior('ABUSIVE_BEHAVIOR', 'Abusive behavior'),
  other('OTHER', 'Other');

  const UserReportReason(this.wire, this.label);

  final String wire;
  final String label;
}
