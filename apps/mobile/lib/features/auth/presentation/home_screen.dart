import 'package:flutter/material.dart';

import '../../location/data/location_acquisition.dart';
import '../../location/data/locality_model.dart';
import '../../location/data/locality_service.dart';
import '../../location/data/location_update_service.dart';
import '../../users/data/users_service.dart';
import '../../users/presentation/profile_screen.dart';
import '../../posts/data/posts_service.dart';
import '../../feed/data/feed_service.dart';
import '../../feed/presentation/feed_screen.dart';
import '../data/auth_exception.dart';
import '../data/models/user_model.dart';

/// Temporary authenticated screen displaying user information and logout functionality.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.onUserUpdated,
    this.usersService,
    this.locationUpdateService,
    this.localityService,
    this.postsService,
    this.feedService,
  });

  final UserModel user;
  final VoidCallback onLogout;
  final ValueChanged<UserModel>? onUserUpdated;
  final UsersService? usersService;
  final LocationUpdateService? locationUpdateService;
  final LocalityService? localityService;
  final PostsService? postsService;
  final FeedService? feedService;

  Future<void> _updateLocation(BuildContext context) async {
    try {
      await (locationUpdateService ?? LocationUpdateService())
          .updateCurrentLocation();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }
    } on LocationAcquisitionException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update location. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          user: user,
          usersService: usersService,
          onUserUpdated: onUserUpdated,
          onSessionExpired: onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khabro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logged in',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.name != null && user.name!.isNotEmpty) ...[
                          Text(
                            user.name!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                        ],
                        _buildInfoRow('Phone', user.phone),
                        const SizedBox(height: 8),
                        _buildInfoRow('Status', user.status),
                        const SizedBox(height: 8),
                        _buildInfoRow('Trust Score', '${user.trustScore}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _LocalitySection(localityService: localityService),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeedScreen(
                          feedService: feedService,
                          postsService: postsService,
                          localityService: localityService,
                          onUpdateLocation: () => _updateLocation(context),
                          onSessionExpired: onLogout,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.view_list_outlined),
                    label: const Text('OPEN LOCAL FEED'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _updateLocation(context),
                    icon: const Icon(Icons.my_location),
                    label: const Text('UPDATE MY LOCATION'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _openProfile(context),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('PROFILE'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class _LocalitySection extends StatefulWidget {
  const _LocalitySection({this.localityService});

  final LocalityService? localityService;

  @override
  State<_LocalitySection> createState() => _LocalitySectionState();
}

class _LocalitySectionState extends State<_LocalitySection> {
  LocalityModel? _locality;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _showLocality() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locality = await (widget.localityService ?? LocalityService())
          .getMyLocality();
      if (!mounted) return;
      setState(() {
        _locality = locality;
        _isLoading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load your locality. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showLocality,
            icon: const Icon(Icons.home_work_outlined),
            label: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SHOW MY LOCALITY'),
          ),
        ),
        if (_locality != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Local Area',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _localityRow('Locality', _locality!.name),
                  _localityRow('City', _locality!.city),
                  _localityRow('State', _locality!.state),
                  _localityRow('Country', _locality!.country),
                ],
              ),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _localityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
