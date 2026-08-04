import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/screens/admin_dashboard_export.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_return_gate.dart';
import '../widgets/pending_recipe_restore_gate.dart';
import 'onboarding_flow_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool? _onboardingCompleted;

  Widget get _loadingShell => const ColoredBox(
        color: AppTheme.darkBackground,
        child: SizedBox.expand(),
      );

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final done = await OnboardingService.instance.isCompleted();
    if (!mounted) return;
    setState(() => _onboardingCompleted = done);
  }

  void _onOnboardingFinished() {
    setState(() => _onboardingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      return _loadingShell;
    }

    if (_onboardingCompleted == false) {
      return OnboardingFlowPage(onFinished: _onOnboardingFinished);
    }

    return PaymentReturnGate(
      child: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingShell;
          }

          final user = snapshot.data;

          if (user == null) {
            return const RestorableLandingPage();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _loadingShell;
              }

              if (userSnapshot.hasError ||
                  userSnapshot.data == null ||
                  !userSnapshot.data!.exists) {
                return const RestorableLandingPage();
              }

              final data =
                  userSnapshot.data!.data() as Map<String, dynamic>?;

              if (data?['role'] == 'admin') {
                return const AdminDashboard();
              }
              return const RestorableLandingPage();
            },
          );
        },
      ),
    );
  }
}
