import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// Firebase Connection Test Widget
/// Use this to verify your Firebase setup is working correctly
class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final List<String> _logs = [];
  bool _isTesting = false;

  void _addLog(String message, {bool isError = false, bool isSuccess = false}) {
    setState(() {
      String prefix = '';
      if (isError) prefix = '❌ ';
      if (isSuccess) prefix = '✅ ';
      _logs.add('$prefix$message');
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
    });

    _addLog('🔍 Starting Firebase Connection Tests...');
    _addLog('═' * 40);

    // Test 1: Firebase Initialization
    _addLog('\n📱 Test 1: Firebase Initialization');
    try {
      final app = Firebase.app();
      _addLog('Project ID: ${app.options.projectId}', isSuccess: true);
      _addLog('Auth Domain: ${app.options.authDomain}', isSuccess: true);
      _addLog('API Key: ${app.options.apiKey.substring(0, 10)}...', isSuccess: true);
    } catch (e) {
      _addLog('Firebase not initialized: $e', isError: true);
      setState(() => _isTesting = false);
      return;
    }

    // Test 2: Firebase Auth Connection
    _addLog('\n🔐 Test 2: Firebase Authentication');
    try {
      final auth = FirebaseAuth.instance;
      _addLog('Current user: ${auth.currentUser?.email ?? "None (not logged in)"}');
      _addLog('Auth instance created successfully', isSuccess: true);
    } catch (e) {
      _addLog('Auth error: $e', isError: true);
    }

    // Test 3: Firestore Connection
    _addLog('\n📚 Test 3: Firestore Database');
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Try to access settings
      final testDoc = await firestore
          .collection('test_connection')
          .doc('test')
          .get();
      
      _addLog('Firestore connection successful', isSuccess: true);
      _addLog('Can read from Firestore: ${testDoc.exists ? "Yes" : "No (doc not found)"}');
    } catch (e) {
      _addLog('Firestore error: $e', isError: true);
    }

    // Test 4: Try Creating a Test User (This will show the API key issue)
    _addLog('\n👤 Test 4: Firebase Auth - Create Test User');
    _addLog('Testing API key validity...');
    
    try {
      final auth = FirebaseAuth.instance;
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'TestPassword123';
      
      _addLog('Attempting to create test user...');
      _addLog('Email: $testEmail');
      
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      _addLog('Test user created successfully!', isSuccess: true);
      _addLog('User ID: ${userCredential.user?.uid}');
      
      // Clean up - delete test user
      _addLog('Cleaning up test user...');
      await userCredential.user?.delete();
      _addLog('Test user deleted', isSuccess: true);
      
    } on FirebaseAuthException catch (e) {
      _addLog('Auth error code: ${e.code}', isError: true);
      _addLog('Auth error message: ${e.message}', isError: true);
      
      if (e.code == 'api-key-not-valid.-please-pass-a-valid-api-key.') {
        _addLog('', isError: true);
        _addLog('🚨 API KEY ERROR DETECTED!', isError: true);
        _addLog('Your Firebase API key is invalid or restricted.', isError: true);
        _addLog('', isError: true);
        _addLog('📋 How to fix:', isError: true);
        _addLog('1. Go to Google Cloud Console', isError: true);
        _addLog('2. Navigate to APIs & Services > Credentials', isError: true);
        _addLog('3. Click on your Web API Key', isError: true);
        _addLog('4. Set Application restrictions to "None"', isError: true);
        _addLog('5. Set API restrictions to "Don\'t restrict key"', isError: true);
        _addLog('6. Save and wait 5-10 minutes', isError: true);
        _addLog('7. Restart your app', isError: true);
      }
    } catch (e) {
      _addLog('Unexpected error: $e', isError: true);
    }

    _addLog('\n═' * 40);
    _addLog('🏁 Tests completed!');

    setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔧 Firebase Diagnostics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test your Firebase connection and API key validity',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isTesting ? null : _runTests,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isTesting ? 'Testing...' : 'Run Connection Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Test Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Click "Run Connection Tests" to start',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color textColor = Colors.white;
                          
                          if (log.contains('❌')) {
                            textColor = Colors.red;
                          } else if (log.contains('✅')) {
                            textColor = Colors.green;
                          } else if (log.contains('🚨')) {
                            textColor = Colors.orange;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: textColor,
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Common Issues:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• API Key Invalid: Check Google Cloud Console restrictions',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '• Auth Not Enabled: Enable Email/Password in Firebase Console',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '• Firestore Error: Check Firestore rules and database creation',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
