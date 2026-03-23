import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/screens/admin_dashboard.dart';
import '../screens/user_account_page.dart';
import 'landing_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get the current user
        final user = snapshot.data;
        
        print('🔐 Auth state: ${user != null ? "Logged in as ${user.email}" : "Not logged in"}');

        if (user == null) {
          // User not logged in, show landing page
          return const LandingPage();
        }

        // User is logged in, check if admin using StreamBuilder for real-time updates
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your profile...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
            }

            if (userSnapshot.hasError) {
              print('❌ Error loading user: ${userSnapshot.error}');
              return const LandingPage();
            }

            final userData = userSnapshot.data;
            
            if (userData == null || !userData.exists) {
              print('⚠️ User document not found');
              return const LandingPage();
            }

            final data = userData.data() as Map<String, dynamic>?;
            final isAdmin = data?['role'] == 'admin';
            
            print('👤 User role: ${data?['role']} | Is Admin: $isAdmin');

            if (isAdmin) {
              // User is admin, show admin dashboard
              return const AdminDashboard();
            } else {
              // Regular user, show user account page
              return const UserAccountPage();
            }
          },
        );
      },
    );
  }
}
