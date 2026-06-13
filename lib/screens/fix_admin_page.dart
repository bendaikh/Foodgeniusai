import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class FixAdminPage extends StatefulWidget {
  const FixAdminPage({super.key});

  @override
  State<FixAdminPage> createState() => _FixAdminPageState();
}

class _FixAdminPageState extends State<FixAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;
  String _statusMessage = '';
  Color _statusColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Admin Account'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
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
                  Icons.build,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fix Admin Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This tool will update admin@gourmetai.com to have admin privileges.',
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
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Fix Admin Role Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _fixAdminRole,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.admin_panel_settings),
                    label: Text(_isProcessing ? 'Processing...' : 'Fix Admin Role'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Create Admin Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _createAdminAccount,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Create Admin Account'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
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
              child: Text(
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

  Future<void> _fixAdminRole() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Searching for admin account...';
      _statusColor = Colors.blue;
    });

    try {
      // Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@gourmetai.com')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _statusMessage = '❌ No user found with email admin@gourmetai.com\n\n'
              'Try clicking "Create Admin Account" instead.';
          _statusColor = Colors.red;
          _isProcessing = false;
        });
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;

      // Update the user document to have admin role
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'name': 'Admin User',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
      });

      setState(() {
        _statusMessage = '✅ Admin role updated successfully!\n\n'
            'User ID: $userId\n'
            'Email: admin@gourmetai.com\n'
            'Role: admin\n\n'
            'You can now log in with the credentials above.';
        _statusColor = Colors.green;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _statusColor = Colors.red;
        _isProcessing = false;
      });
    }
  }

  Future<void> _createAdminAccount() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating admin account...';
      _statusColor = Colors.blue;
    });

    const email = 'admin@gourmetai.com';
    const password = 'Admin123456';
    const name = 'Admin User';

    try {
      // Try to create the account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create admin user document
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'name': name,
        'role': 'admin',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out the newly created user
      await _auth.signOut();

      setState(() {
        _statusMessage = '✅ Admin account created successfully!\n\n'
            'Email: admin@gourmetai.com\n'
            'Password: Admin123456\n\n'
            'You can now log in with these credentials.';
        _statusColor = Colors.green;
        _isProcessing = false;
      });
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        // Account exists, try to update it instead
        setState(() {
          _statusMessage = '⚠️ Account already exists. Updating role...';
          _statusColor = Colors.orange;
        });
        await _fixAdminRole();
      } else {
        setState(() {
          _statusMessage = '❌ Error: $e';
          _statusColor = Colors.red;
          _isProcessing = false;
        });
      }
    }
  }
}
