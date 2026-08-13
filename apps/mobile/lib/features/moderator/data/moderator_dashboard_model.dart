class ModeratorDashboardModel {
  const ModeratorDashboardModel({
    required this.openPostReports,
    required this.openUserReports,
    required this.openCommentReports,
    required this.activeCivicComplaints,
  });

  factory ModeratorDashboardModel.fromJson(Map<String, dynamic> json) {
    return ModeratorDashboardModel(
      openPostReports: (json['openPostReports'] as num?)?.toInt() ?? 0,
      openUserReports: (json['openUserReports'] as num?)?.toInt() ?? 0,
      openCommentReports: (json['openCommentReports'] as num?)?.toInt() ?? 0,
      activeCivicComplaints: (json['activeCivicComplaints'] as num?)?.toInt() ?? 0,
    );
  }

  final int openPostReports;
  final int openUserReports;
  final int openCommentReports;
  final int activeCivicComplaints;
}
