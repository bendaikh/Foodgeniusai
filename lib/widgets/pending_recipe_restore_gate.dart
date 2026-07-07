import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/pending_recipe_service.dart';
import '../screens/landing_page.dart';
import '../screens/recipe_detail_page.dart';

/// Restores a guest-generated recipe after the user returns from mobile checkout.
class PendingRecipeRestoreGate extends StatefulWidget {
  final Widget child;

  const PendingRecipeRestoreGate({super.key, required this.child});

  @override
  State<PendingRecipeRestoreGate> createState() =>
      _PendingRecipeRestoreGateState();
}

class _PendingRecipeRestoreGateState extends State<PendingRecipeRestoreGate>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _hasRestored = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      _tryRestorePendingRecipe();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasRestored) {
      _tryRestorePendingRecipe();
    }
  }

  Future<void> _tryRestorePendingRecipe() async {
    if (kIsWeb || _isChecking || _hasRestored || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final hasLocalPending = PendingRecipeService.instance.loadLocal() != null;
    if (!hasLocalPending) return;

    _isChecking = true;

    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profile = profileDoc.data();

      if (!_authService.hasPaidSubscription(profile)) return;

      final recipe = await PendingRecipeService.instance.claimAndPersist(
        userId: user.uid,
      );

      if (!mounted || recipe == null) return;

      _hasRestored = true;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
        (route) => false,
      );
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Landing page wrapped with pending-recipe restore for mobile app resume.
class RestorableLandingPage extends StatelessWidget {
  const RestorableLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PendingRecipeRestoreGate(
      child: LandingPage(),
    );
  }
}
