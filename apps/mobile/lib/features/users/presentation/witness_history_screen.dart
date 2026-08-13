import 'package:flutter/material.dart';
import '../../posts/data/posts_service.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../data/users_service.dart';
import '../data/witness_history_model.dart';

class WitnessHistoryScreen extends StatefulWidget {
  const WitnessHistoryScreen({
    super.key,
    this.usersService,
    this.postsService,
  });

  final UsersService? usersService;
  final PostsService? postsService;

  @override
  State<WitnessHistoryScreen> createState() => _WitnessHistoryScreenState();
}

class _WitnessHistoryScreenState extends State<WitnessHistoryScreen> {
  late final UsersService _usersService;
  late final PostsService _postsService;

  List<WitnessHistoryModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _postsService = widget.postsService ?? PostsService();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _usersService.getMyWitnessHistory();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load witness history.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Witness History'),
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
                onPressed: _loadHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          "You haven't witnessed any posts yet.",
          style: TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.post.content),
            subtitle: Text(
              'Witnessed ${_formatTime(item.createdAt)} • Author: ${item.post.author?.name ?? "Anonymous"}',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    post: item.post,
                    postsService: _postsService,
                  ),
                ),
              );
            },
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
