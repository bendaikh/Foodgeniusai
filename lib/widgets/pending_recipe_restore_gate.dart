import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/pending_recipe_service.dart';
import '../services/recipe_generation_service.dart';
import '../utils/recipe_navigation.dart';
import '../screens/landing_page.dart';

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
  final RecipeGenerationService _recipeGenerationService = RecipeGenerationService();
  bool _isChecking = false;
  bool _hasRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryRestorePendingRecipe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasRestored) {
      _tryRestorePendingRecipe();
    }
  }

  Future<void> _tryRestorePendingRecipe() async {
    if (_isChecking || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final hasLocalPending = PendingRecipeService.instance.loadLocal() != null;
    final hasCloudPending = await _hasCloudPending(user.uid);
    if (!hasLocalPending && !hasCloudPending) {
      await _recipeGenerationService.syncPendingToMyRecipes();
      return;
    }

    _isChecking = true;

    try {
      final recipe = await _recipeGenerationService.syncPendingToMyRecipes();

      if (!mounted || recipe == null) return;

      _hasRestored = true;
      RecipeNavigation.openRecipeDetailFromCheckout(context, recipe);
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _hasCloudPending(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pending_recipes')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
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
