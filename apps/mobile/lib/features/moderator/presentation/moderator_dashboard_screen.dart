import 'package:flutter/material.dart';

import '../../auth/data/auth_exception.dart';
import '../../advertisements/data/advertisement_service.dart';
import '../data/moderator_dashboard_model.dart';
import '../data/moderator_service.dart';
import 'moderator_report_list_screen.dart';
import 'moderator_complaint_list_screen.dart';
import 'moderator_feedback_list_screen.dart';
import 'moderator_advertisements_screen.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({
    super.key,
    required this.moderatorService,
    this.advertisementService,
  });

  final ModeratorService moderatorService;
  final AdvertisementService? advertisementService;

  @override
  State<ModeratorDashboardScreen> createState() => _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int? _statusCode;
  ModeratorDashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusCode = null;
    });

    try {
      final data = await widget.moderatorService.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _statusCode = e.statusCode;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _navigateToFeedback() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorFeedbackListScreen(
          moderatorService: widget.moderatorService,
        ),
      ),
    ).then((_) => _loadDashboard());
  }

  void _navigateToReports(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorReportListScreen(
          moderatorService: widget.moderatorService,
          initialType: type,
        ),
      ),
    ).then((_) => _loadDashboard());
  }

  void _navigateToComplaints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorComplaintListScreen(
          moderatorService: widget.moderatorService,
        ),
      ),
    ).then((_) => _loadDashboard());
  }

  void _navigateToAdvertisements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeratorAdvertisementsScreen(
          advertisementService:
              widget.advertisementService ?? AdvertisementService(),
        ),
      ),
    );
  }

  Widget _buildStatTile(String count, String label, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFF1565C0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_statusCode == 403) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderator')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Moderator privileges required.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('BACK'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Moderator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboard,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatTile(
                            '${_dashboard!.openPostReports}',
                            'Open Reports',
                            () => _navigateToReports('ALL'),
                          ),
                          _buildStatTile(
                            '${_dashboard!.openCommentReports}',
                            'Comment Reports',
                            () => _navigateToReports('COMMENT'),
                          ),
                          _buildStatTile(
                            '${_dashboard!.openUserReports}',
                            'User Reports',
                            () => _navigateToReports('USER'),
                          ),
                          _buildStatTile(
                            '${_dashboard!.activeCivicComplaints}',
                            'Civic Complaints',
                            _navigateToComplaints,
                          ),
                          _buildStatTile(
                            '${_dashboard!.openFeedback}',
                            'Open Feedback',
                            _navigateToFeedback,
                          ),
                          _buildStatTile(
                            'Ads',
                            'Advertisements',
                            _navigateToAdvertisements,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildActionButton('All Reports', () => _navigateToReports('ALL')),
                          const SizedBox(height: 8),
                          _buildActionButton('Post Reports', () => _navigateToReports('POST')),
                          const SizedBox(height: 8),
                          _buildActionButton('User Reports', () => _navigateToReports('USER')),
                          const SizedBox(height: 8),
                          _buildActionButton('Comment Reports', () => _navigateToReports('COMMENT')),
                          const SizedBox(height: 8),
                          _buildActionButton('Feedback', _navigateToFeedback),
                          const SizedBox(height: 8),
                          _buildActionButton('Advertisements', _navigateToAdvertisements),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Civic Complaints',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton('Active Complaints', _navigateToComplaints),
                    ],
                  ),
                ),
    );
  }
}
