import 'package:flutter/material.dart';
import '../data/post_category.dart';
import '../data/post_model.dart';
import '../data/posts_service.dart';
import 'post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.postsService});

  final PostsService? postsService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final PostsService _postsService;
  final TextEditingController _queryController = TextEditingController();

  List<PostModel> _results = [];
  bool _hasSearched = false;
  bool _isLoading = false;
  String? _errorMessage;

  PostCategory? _selectedCategory;
  bool _isVerified = false;
  bool _isRecent = false;
  double? _selectedRadiusKm;

  @override
  void initState() {
    super.initState();
    _postsService = widget.postsService ?? PostsService();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final queryText = _queryController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final response = await _postsService.searchPosts(
        query: queryText.isEmpty ? null : queryText,
        category: _selectedCategory?.wireValue,
        verified: _isVerified ? true : null,
        recent: _isRecent ? true : null,
        radiusKm: _selectedRadiusKm,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _results = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to search posts';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Posts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Search keyword...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_selectedCategory?.label ?? 'Category'),
                  selected: _selectedCategory != null,
                  onSelected: (selected) {
                    if (!selected) {
                      setState(() => _selectedCategory = null);
                    } else {
                      _showCategoryPicker();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Verified'),
                  selected: _isVerified,
                  onSelected: (val) {
                    setState(() => _isVerified = val);
                    _performSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Recent'),
                  selected: _isRecent,
                  onSelected: (val) {
                    setState(() => _isRecent = val);
                    _performSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    _selectedRadiusKm == null
                        ? 'Radius'
                        : '${_selectedRadiusKm!.toInt()} km',
                  ),
                  selected: _selectedRadiusKm != null,
                  onSelected: (selected) {
                    if (!selected) {
                      setState(() => _selectedRadiusKm = null);
                      _performSearch();
                    } else {
                      _showRadiusPicker();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
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
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Search local posts',
          style: TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No posts found',
          style: TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final post = _results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(post.content),
            subtitle: Text(
              '${post.author?.name ?? "Anonymous"} • ${_formatTime(post.createdAt)}',
            ),
            trailing: post.category != null
                ? Chip(
                    label: Text(
                      PostCategory.fromWire(post.category).label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    post: post,
                    postsService: _postsService,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Categories'),
            onTap: () {
              Navigator.of(modalContext).pop();
              setState(() => _selectedCategory = null);
              _performSearch();
            },
          ),
          ...PostCategory.values.map(
            (cat) => ListTile(
              title: Text(cat.label),
              onTap: () {
                Navigator.of(modalContext).pop();
                setState(() => _selectedCategory = cat);
                _performSearch();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => ListView(
        shrinkWrap: true,
        children: [1.0, 3.0, 5.0, 10.0, 25.0]
            .map(
              (r) => ListTile(
                title: Text('${r.toInt()} km'),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  setState(() => _selectedRadiusKm = r);
                  _performSearch();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
