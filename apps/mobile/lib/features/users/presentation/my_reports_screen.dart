import 'package:flutter/material.dart';
import '../data/my_report_model.dart';
import '../data/users_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key, this.usersService});

  final UsersService? usersService;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final UsersService _usersService;
  List<MyReportModel> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _usersService.getMyReports();
      if (!mounted) return;
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load reports.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text(
          "You haven't submitted any reports.",
          style: TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.separated(
        itemCount: _reports.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _reports[index];
          return ListTile(
            title: Text('${item.type} Report: ${item.reason}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.targetContentSnippet != null)
                  Text('Post: "${item.targetContentSnippet}"'),
                if (item.targetUserName != null)
                  Text('User: ${item.targetUserName}'),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(item.description!),
                const SizedBox(height: 4),
                Text(
                  _formatTime(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                item.status,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
