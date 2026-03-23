import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

/// Admin Password Reset / Re-creation Page
/// Use this to fix admin login issues
class AdminPasswordResetPage extends StatefulWidget {
  const AdminPasswordResetPage({super.key});

  @override
  State<AdminPasswordResetPage> createState() => _AdminPasswordResetPageState();
}

class _AdminPasswordResetPageState extends State<AdminPasswordResetPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isProcessing = false;
  String _message = '';
  Color _messageColor = Colors.white;
  
  final String _adminEmail = 'admin@gourmetai.com';
  final String _adminPassword = 'Admin123456';

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isProcessing = true;
      _message = 'Sending password reset email...';
      _messageColor = Colors.orange;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _adminEmail);
      
      setState(() {
        _isProcessing = false;
        _message = '✅ Password reset email sent!\n\n'
            'Check inbox for: $_adminEmail\n\n'
            'Click the link in the email to set a new password.';
        _messageColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Error: $e';
        _messageColor = Colors.red;
      });
    }
  }

  Future<void> _recreateAdminAccount() async {
    setState(() {
      _isProcessing = true;
      _message = 'Attempting to recreate admin account...';
      _messageColor = Colors.orange;
    });

    try {
      // First, try to delete any existing auth user by signing in
      try {
        // Try signing in with the expected password
        final credential = await _auth.signInWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );
        
        // If we got here, password is correct - account exists and works!
        await _auth.signOut();
        
        setState(() {
          _isProcessing = false;
          _message = '✅ Admin account already exists and password is correct!\n\n'
              'Email: $_adminEmail\n'
              'Password: $_adminPassword\n\n'
              'Try logging in again.';
          _messageColor = Colors.green;
        });
        return;
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // User doesn't exist in Auth, create it
          print('User not found in Auth, creating...');
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // User exists but with different password
          setState(() {
            _isProcessing = false;
            _message = '⚠️ Admin account exists but with a different password.\n\n'
                'Options:\n'
                '1. Click "Send Password Reset Email" button\n'
                '2. Or check Firebase Console for the correct password\n\n'
                'Email: $_adminEmail';
            _messageColor = Colors.orange;
          });
          return;
        } else {
          throw e;
        }
      }

      // Create new admin user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      final userId = userCredential.user!.uid;

      // Create/Update admin user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': _adminEmail,
        'name': 'Admin User',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'role': 'admin',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out
      await _auth.signOut();

      setState(() {
        _isProcessing = false;
        _message = '✅ Admin account created successfully!\n\n'
            'Email: $_adminEmail\n'
            'Password: $_adminPassword\n\n'
            'You can now log in!';
        _messageColor = Colors.green;
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _isProcessing = false;
          _message = '⚠️ Email already in use in Firebase Auth.\n\n'
              'The account exists but you may have set a different password.\n\n'
              'Click "Send Password Reset Email" to reset it.';
          _messageColor = Colors.orange;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _message = '❌ Error: ${e.message}\n\nCode: ${e.code}';
          _messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Error: $e';
        _messageColor = Colors.red;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isProcessing = true;
      _message = 'Testing login...';
      _messageColor = Colors.orange;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      // Check if user is admin in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      String role = 'unknown';
      if (userDoc.exists) {
        role = userDoc.data()?['role'] ?? 'user';
      }

      await _auth.signOut();

      setState(() {
        _isProcessing = false;
        _message = '✅ LOGIN SUCCESSFUL!\n\n'
            'User ID: ${credential.user!.uid}\n'
            'Email: ${credential.user!.email}\n'
            'Role: $role\n\n'
            'You can now go to Admin Login and sign in!';
        _messageColor = Colors.green;
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Login failed!\n\n'
            'Error: ${e.message}\n'
            'Code: ${e.code}\n\n'
            'Try "Recreate Admin Account" or "Send Password Reset Email"';
        _messageColor = Colors.red;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Error: $e';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Admin Login'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Fix Admin Login Issues',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use these tools to fix admin authentication problems',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Credentials Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔑 Expected Admin Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: $_adminEmail',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Password: $_adminPassword',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Test Login Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _testLogin,
                icon: const Icon(Icons.login),
                label: const Text('1. Test Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try logging in with the credentials above',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Recreate Account Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _recreateAdminAccount,
                icon: const Icon(Icons.refresh),
                label: const Text('2. Recreate Admin Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creates admin in Firebase Auth + Firestore',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Password Reset Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _sendPasswordResetEmail,
                icon: const Icon(Icons.email),
                label: const Text('3. Send Password Reset Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'If account exists but password is wrong',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Status Message
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _messageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _messageColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: CircularProgressIndicator(),
                        ),
                      Text(
                        _message,
                        style: TextStyle(color: _messageColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Back to Admin Login
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go to Admin Login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
