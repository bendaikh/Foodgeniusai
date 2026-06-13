import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ForceCreateAdminPage extends StatefulWidget {
  const ForceCreateAdminPage({super.key});

  @override
  State<ForceCreateAdminPage> createState() => _ForceCreateAdminPageState();
}

class _ForceCreateAdminPageState extends State<ForceCreateAdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;
  String _statusMessage = '';
  Color _statusColor = Colors.white;
  String _userUid = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Force Create Admin User'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.engineering,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Force Create Admin User in Firestore',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This tool will recreate the admin user document in Firestore even if the users collection was deleted.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Status message
                if (_statusMessage.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: SelectableText(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Step 1: Get User UID
                _buildSection(
                  '1',
                  'Get Firebase Auth User UID',
                  'First, we need to find the User UID from Firebase Authentication',
                  [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _getAuthUsers,
                      icon: const Icon(Icons.person_search),
                      label: const Text('Get Admin User UID'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(color: AppTheme.greyText),
                const SizedBox(height: 24),
                
                // Step 2: Create Firestore Document
                _buildSection(
                  '2',
                  'Create Firestore User Document',
                  'Create the user document in Firestore with admin role',
                  [
                    if (_userUid.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'User UID: $_userUid',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _isProcessing || _userUid.isEmpty
                          ? null
                          : _createFirestoreDocument,
                      icon: const Icon(Icons.save),
                      label: const Text('Create Firestore Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Divider(color: AppTheme.greyText),
                const SizedBox(height: 16),
                
                const Text(
                  'Admin Credentials:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCredentialRow('Email:', 'admin@gourmetai.com'),
                _buildCredentialRow('Password:', 'Admin123456'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String number,
    String title,
    String description,
    List<Widget> actions,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyText.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 16),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                value,
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getAuthUsers() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Checking Firebase Authentication...';
      _statusColor = Colors.blue;
    });

    try {
      // Check if user is currently signed in
      final currentUser = _auth.currentUser;
      
      if (currentUser != null && currentUser.email == 'admin@gourmetai.com') {
        setState(() {
          _userUid = currentUser.uid;
          _statusMessage = '✅ Found admin user in Firebase Auth!\n\n'
              'User UID: ${currentUser.uid}\n'
              'Email: ${currentUser.email}\n\n'
              'Now click "Create Firestore Document" to create the user document with admin role.';
          _statusColor = Colors.green;
          _isProcessing = false;
        });
        return;
      }

      // Try to sign in to get the UID
      setState(() {
        _statusMessage = 'Attempting to sign in to get User UID...';
        _statusColor = Colors.blue;
      });

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: 'admin@gourmetai.com',
        password: 'Admin123456',
      );

      setState(() {
        _userUid = userCredential.user!.uid;
        _statusMessage = '✅ Successfully signed in!\n\n'
            'User UID: ${userCredential.user!.uid}\n'
            'Email: ${userCredential.user!.email}\n\n'
            'Now click "Create Firestore Document" below.';
        _statusColor = Colors.green;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e\n\n'
            'The admin@gourmetai.com account might not exist in Firebase Authentication.\n\n'
            'Please go to Firebase Console → Authentication → Users and create the user first.';
        _statusColor = Colors.red;
        _isProcessing = false;
      });
    }
  }

  Future<void> _createFirestoreDocument() async {
    if (_userUid.isEmpty) {
      setState(() {
        _statusMessage = '❌ Error: No User UID found. Run Step 1 first.';
        _statusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating Firestore document...';
      _statusColor = Colors.blue;
    });

    try {
      // Create the user document with admin role
      await _firestore.collection('users').doc(_userUid).set({
        'uid': _userUid,
        'email': 'admin@gourmetai.com',
        'name': 'Admin User',
        'role': 'admin',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _statusMessage = '✅ SUCCESS! Admin user created in Firestore!\n\n'
            'Collection: users\n'
            'Document ID: $_userUid\n'
            'Email: admin@gourmetai.com\n'
            'Role: admin\n'
            'Subscription: elite\n\n'
            '🎉 You can now log in to the admin panel!\n\n'
            'Go to /#/admin and use:\n'
            'Email: admin@gourmetai.com\n'
            'Password: Admin123456';
        _statusColor = Colors.green;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error creating Firestore document: $e\n\n'
            'Possible causes:\n'
            '1. Firestore security rules are blocking writes\n'
            '2. No internet connection\n'
            '3. Firebase project configuration issue\n\n'
            'Check the browser console (F12) for more details.';
        _statusColor = Colors.red;
        _isProcessing = false;
      });
      
      // Print to console for debugging
      print('Error creating Firestore document: $e');
    }
  }
}
