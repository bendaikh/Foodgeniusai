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
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show nothing — the HTML splash is still covering the screen
          return const SizedBox.shrink();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LandingPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            if (userSnapshot.hasError ||
                userSnapshot.data == null ||
                !userSnapshot.data!.exists) {
              return const LandingPage();
            }

            final data =
                userSnapshot.data!.data() as Map<String, dynamic>?;

            if (data?['role'] == 'admin') {
              return const AdminDashboard();
            }
            return const LandingPage();
          },
        );
      },
    );
  }
}
