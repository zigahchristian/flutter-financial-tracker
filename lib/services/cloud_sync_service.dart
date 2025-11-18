import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class CloudSyncService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata', // AppData folder scope
      'https://www.googleapis.com/auth/drive.file', // Drive file scope
    ],
    signInOption: SignInOption.standard, // Use standard sign-in
  );

  static final DatabaseHelper _dbHelper = DatabaseHelper();
  static final String _syncKey = 'last_sync_timestamp';

  // Initialize Google Sign-In
  static Future<void> initialize() async {
    try {
      // Try to sign in silently first
      await _googleSignIn.signInSilently();
    } catch (e) {
      print('Silent sign-in failed: $e');
      // This is normal if user hasn't signed in before
    }
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      final account = _googleSignIn.currentUser;
      return account != null;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  // Sign in to Google - returns a result map to match UI expectations
  static Future<Map<String, dynamic>> signIn() async {
    // Prevent calling plugin on unsupported desktop platforms where
    // the google_sign_in plugin may not have a native implementation.
    if (!kIsWeb && !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      print('Google Sign-In not supported on this platform: $defaultTargetPlatform');
      return {
        'success': false,
        'message': 'Google Sign-In is not supported on this platform',
        'errorCode': 'UNSUPPORTED_PLATFORM',
      };
    }
    try {
      print('Starting Google Sign-In...');
      final account = await _googleSignIn.signIn();

      if (account != null) {
        print('Sign-in successful: ${account.email}');
        // Ensure auth headers are available
        try {
          final headers = await account.authHeaders;
          if (headers['Authorization'] == null) {
            print('Auth headers missing after sign-in');
          }
        } catch (e) {
          print('Warning getting auth headers: $e');
        }

        return {
          'success': true,
          'message': 'Signed in as ${account.email}',
          'account': account,
        };
      } else {
        print('Sign-in cancelled by user');
        return {
          'success': false,
          'message': 'Sign-in cancelled by user',
          'errorCode': 'CANCELLED',
        };
      }
    } catch (error) {
      print('Google Sign-In error: $error');
      print('Error type: ${error.runtimeType}');

      var code = 'SIGN_IN_FAILED';
      final msg = error.toString();
      // Map MissingPluginException and other common plugin errors
      if (msg.contains('MissingPluginException') || msg.contains('No implementation found for method')) {
        code = 'MISSING_PLUGIN';
      }
      if (msg.contains('NETWORK_ERROR')) code = 'NETWORK_ERROR';
      else if (msg.contains('DEVELOPER_ERROR')) code = 'DEVELOPER_ERROR';
      else if (msg.contains('SCOPE')) code = 'SCOPE_DENIED';
      else if (msg.contains('INVALID_ACCOUNT')) code = 'INVALID_ACCOUNT';

      return {
        'success': false,
        'message': 'Google sign-in failed',
        'errorCode': code,
        'error': msg,
      };
    }
  }

  // Sign out from Google - returns result map for UI
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _clearSyncTimestamp();
      print('Sign-out successful');
      return {
        'success': true,
        'message': 'Signed out successfully',
      };
    } catch (e) {
      print('Error during sign-out: $e');
      return {
        'success': false,
        'message': 'Error signing out: ${e.toString()}',
      };
    }
  }

  // Get current user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get authentication headers with validation
  static Future<Map<String, String>?> getAuthHeaders() async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('No user signed in');
      }
      
      final headers = await user.authHeaders;
      if (headers['Authorization'] == null) {
        throw Exception('No authorization token available');
      }
      
      return headers;
    } catch (e) {
      print('Error getting auth headers: $e');
      return null;
    }
  }

  // Simple backup to Google Drive using App Data folder
  static Future<bool> backupData() async {
    try {
      final authHeaders = await getAuthHeaders();
      if (authHeaders == null) {
        throw Exception('Please sign in to Google first');
      }

      // Create backup data
      final backupData = await _createBackupData();
      
      // Upload to Google Drive App Data folder
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
        headers: {
          'Authorization': authHeaders['Authorization']!,
          'Content-Type': 'multipart/related; boundary="boundary"',
        },
        body: _createMultipartBody(backupData),
      );

      if (response.statusCode == 200) {
        await _saveSyncTimestamp();
        print('Backup successful!');
        return true;
      } else {
        print('Backup failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error backing up data: $e');
      return false;
    }
  }

  // Simple restore from Google Drive - returns result map for UI
  static Future<Map<String, dynamic>> restoreData() async {
    try {
      final authHeaders = await getAuthHeaders();
      if (authHeaders == null) {
        return {
          'success': false,
          'message': 'Please sign in to Google first',
          'action': 'signin_required',
        };
      }

      // Get the latest backup file from App Data folder
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?'
            'q=name="finance_tracker_backup"&'
            'spaces=appDataFolder&'
            'orderBy=modifiedTime desc&'
            'pageSize=1'),
        headers: {
          'Authorization': authHeaders['Authorization']!,
        },
      );

      if (response.statusCode == 200) {
        final files = json.decode(response.body)['files'];
        if (files != null && files.isNotEmpty) {
          final fileId = files[0]['id'];

          // Download the file
          final downloadResponse = await http.get(
            Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
            headers: {
              'Authorization': authHeaders['Authorization']!,
            },
          );

          if (downloadResponse.statusCode == 200) {
            final ok = await _restoreFromBackupData(downloadResponse.body);
            return {
              'success': ok,
              'message': ok ? 'Restore completed successfully' : 'Failed to restore data',
              'action': ok ? 'restore' : 'restore_failed',
            };
          } else {
            return {
              'success': false,
              'message': 'Failed to download backup: ${downloadResponse.statusCode}',
              'action': 'drive_access_failed',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'No backup found. Please create a backup first.',
            'action': 'no_backup',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to list backup files: ${response.statusCode}',
          'action': 'drive_access_failed',
        };
      }
    } catch (e) {
      print('Error restoring data: $e');
      return {
        'success': false,
        'message': 'Error restoring data: ${e.toString()}',
        'action': 'error',
      };
    }
  }

  // Create backup data as JSON
  static Future<String> _createBackupData() async {
    try {
      final sales = await _dbHelper.getSales();
      final expenses = await _dbHelper.getExpenses();

      final backup = {
        'sales': sales,
        'expenses': expenses,
        'timestamp': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'totalRecords': sales.length + expenses.length,
      };

      return json.encode(backup);
    } catch (e) {
      print('Error creating backup data: $e');
      rethrow;
    }
  }

  // Restore from backup data
  static Future<bool> _restoreFromBackupData(String backupData) async {
    try {
      final backup = json.decode(backupData);
      
      if (backup['sales'] != null && backup['expenses'] != null) {
        // Clear existing data
        await _clearExistingData();
        
        int salesCount = 0;
        int expensesCount = 0;
        
        // Restore sales
        for (var sale in backup['sales']) {
          await _dbHelper.insertSale({
            'date': sale['date'],
            'description': sale['description'],
            'amount': sale['amount'],
            'category': sale['category'],
          });
          salesCount++;
        }
        
        // Restore expenses
        for (var expense in backup['expenses']) {
          await _dbHelper.insertExpense({
            'date': expense['date'],
            'description': expense['description'],
            'amount': expense['amount'],
            'category': expense['category'],
          });
          expensesCount++;
        }
        
        await _saveSyncTimestamp();
        print('Restore successful! Imported $salesCount sales and $expensesCount expenses');
        return true;
      } else {
        throw Exception('Invalid backup format');
      }
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }

  // Clear existing data before restore
  static Future<void> _clearExistingData() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('sales');
      await db.delete('expenses');
      print('Cleared existing data');
    } catch (e) {
      print('Error clearing existing data: $e');
      rethrow;
    }
  }

  // Create multipart body for Google Drive upload
  static String _createMultipartBody(String fileContent) {
    final boundary = 'boundary';
    var body = '--$boundary\r\n';
    body += 'Content-Type: application/json; charset=UTF-8\r\n\r\n';
    body += json.encode({
      'name': 'finance_tracker_backup',
      'mimeType': 'application/json',
      'parents': ['appDataFolder'] // Store in app-specific folder (private)
    });
    body += '\r\n--$boundary\r\n';
    body += 'Content-Type: application/json\r\n\r\n';
    body += fileContent;
    body += '\r\n--$boundary--\r\n';
    
    return body;
  }

  // Save last sync timestamp
  static Future<void> _saveSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncKey, DateTime.now().toIso8601String());
      print('Sync timestamp saved');
    } catch (e) {
      print('Error saving sync timestamp: $e');
      rethrow;
    }
  }

  // Clear sync timestamp
  static Future<void> _clearSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncKey);
      print('Sync timestamp cleared');
    } catch (e) {
      print('Error clearing sync timestamp: $e');
      rethrow;
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_syncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  // Get sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final lastSync = await getLastSyncTime();
      final signedIn = await isSignedIn();
      
      return {
        'isSignedIn': signedIn,
        'lastSync': lastSync,
        'hasBackup': lastSync != null,
        'userEmail': (await getCurrentUser())?.email,
      };
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'isSignedIn': false,
        'lastSync': null,
        'hasBackup': false,
        'userEmail': null,
      };
    }
  }

  // Auto sync - simple one-tap sync
  static Future<Map<String, dynamic>> autoSync() async {
    try {
      if (!await isSignedIn()) {
        return {
          'success': false, 
          'message': 'Please sign in to Google first',
          'action': 'signin_required'
        };
      }

      // Always backup current data
      final success = await backupData();
      
      if (success) {
        return {
          'success': true, 
          'message': 'Data synced successfully to Google Drive!',
          'action': 'backup'
        };
      } else {
        return {
          'success': false, 
          'message': 'Sync failed. Please check your connection.',
          'action': 'backup_failed'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'message': 'Sync error: ${e.toString()}',
        'action': 'error'
      };
    }
  }

  // Check if backup exists
  static Future<bool> checkBackupExists() async {
    try {
      final authHeaders = await getAuthHeaders();
      if (authHeaders == null) return false;

      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?'
            'q=name="finance_tracker_backup"&'
            'spaces=appDataFolder&'
            'pageSize=1'),
        headers: {
          'Authorization': authHeaders['Authorization']!,
        },
      );

      if (response.statusCode == 200) {
        final files = json.decode(response.body)['files'];
        return files != null && files.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      print('Error checking backup: $e');
      return false;
    }
  }
}