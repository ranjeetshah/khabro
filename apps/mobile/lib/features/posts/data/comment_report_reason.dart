enum CommentReportReason {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Harassment'),
  abuse('ABUSE', 'Abuse'),
  misleading('MISLEADING', 'Misleading'),
  inappropriate('INAPPROPRIATE', 'Inappropriate Content'),
  other('OTHER', 'Other');

  const CommentReportReason(this.wire, this.label);
  final String wire;
  final String label;
}
