import 'package:flutter/material.dart';
import 'package:faustina/services/cloud_sync_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SimpleCloudSyncPage extends StatefulWidget {
  @override
  _SimpleCloudSyncPageState createState() => _SimpleCloudSyncPageState();
}

class _SimpleCloudSyncPageState extends State<SimpleCloudSyncPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _statusIsError = false;
  Map<String, dynamic> _syncStatus = {};
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await CloudSyncService.getSyncStatus();
      final user = await CloudSyncService.getCurrentUser();
      
      setState(() {
        _syncStatus = status;
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading sync status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
    
    // Clear status after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final user = await CloudSyncService.signIn();
      if (user != null) {
        _showStatus('Signed in successfully as ${user.email}');
        await _loadSyncStatus();
      } else {
        _showStatus('Sign in cancelled', isError: true);
      }
    } catch (e) {
      _showStatus('Error signing in: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await CloudSyncService.signOut();
      _showStatus('Signed out successfully');
      await _loadSyncStatus();
    } catch (e) {
      _showStatus('Error signing out: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final result = await CloudSyncService.autoSync();
      _showStatus(result['message'], isError: !result['success']);
      
      if (result['success']) {
        await _loadSyncStatus();
      }
    } catch (e) {
      _showStatus('Error during sync: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final success = await CloudSyncService.restoreData();
      if (success) {
        _showStatus('Data restored successfully!');
        await _loadSyncStatus();
      } else {
        _showStatus('Restore failed or no backup found', isError: true);
      }
    } catch (e) {
      _showStatus('Error during restore: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatLastSync() {
    final lastSync = _syncStatus['lastSync'];
    if (lastSync == null) return 'Never';
    
    final date = lastSync as DateTime;
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isSignedIn = _syncStatus['isSignedIn'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cloud Sync'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _statusIsError ? Colors.red[50] : Colors.green[50],
                    border: Border.all(
                      color: _statusIsError ? Colors.red : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusIsError ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),

              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      // User Info Section
                      if (isSignedIn && _currentUser != null)
                        _buildUserSection(),

                      SizedBox(height: 24),

                      // Sync Status Section
                      _buildSyncStatusSection(),

                      SizedBox(height: 24),

                      // Actions Section
                      _buildActionsSection(isSignedIn),

                      SizedBox(height: 24),

                      // Info Section
                      _buildInfoSection(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: _currentUser?.photoUrl != null 
                    ? NetworkImage(_currentUser!.photoUrl!) 
                    : null,
                child: _currentUser?.photoUrl == null 
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
                backgroundColor: Colors.blue,
              ),
              title: Text(
                _currentUser?.displayName ?? 'User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_currentUser?.email ?? ''),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStatusItem(
              'Google Account',
              _syncStatus['isSignedIn'] == true ? 'Connected' : 'Not Connected',
              _syncStatus['isSignedIn'] == true ? Icons.check_circle : Icons.circle,
              _syncStatus['isSignedIn'] == true ? Colors.green : Colors.grey,
            ),
            _buildStatusItem(
              'Last Sync',
              _formatLastSync(),
              Icons.access_time,
              _syncStatus['lastSync'] != null ? Colors.blue : Colors.grey,
            ),
            _buildStatusItem(
              'Backup Status',
              _syncStatus['hasBackup'] == true ? 'Available' : 'No Backup',
              _syncStatus['hasBackup'] == true ? Icons.backup : Icons.backup_outlined,
              _syncStatus['hasBackup'] == true ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isSignedIn) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Sync Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (!isSignedIn) ...[
              _buildActionButton(
                'Sign in with Google',
                'Connect your Google account to enable cloud sync',
                Icons.login,
                Colors.blue,
                _signIn,
              ),
            ] else ...[
              _buildActionButton(
                'Sync Now',
                'Backup your data to Google Drive',
                Icons.cloud_upload,
                Colors.green,
                _autoSync,
              ),
              SizedBox(height: 12),
              _buildActionButton(
                'Restore Data',
                'Restore your data from cloud backup',
                Icons.cloud_download,
                Colors.orange,
                _restoreData,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.grey, size: 24),
                SizedBox(width: 8),
                Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoItem('Secure', 'Your data is stored privately in your Google Drive'),
            _buildInfoItem('Automatic', 'One-tap sync backs up all your data'),
            _buildInfoItem('Cross-Device', 'Sync across all your devices'),
            _buildInfoItem('Private', 'Only you can access your backup data'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}