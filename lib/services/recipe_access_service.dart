import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../exceptions/free_recipe_limit_exception.dart';
import '../exceptions/generation_limit_exception.dart';
import 'auth_service.dart';
import 'generation_limit_service.dart';

/// Central entitlement decisions for recipe generation.
enum RecipeAccessDecision {
  allowSubscription,
  allowFree,
  showPaywall,
}

/// Single source of truth for free-recipe + paywall access across all
/// generation entry points (Create Recipe, Kitchen Treasures, Scan Fridge).
class RecipeAccessService {
  RecipeAccessService._();
  static final RecipeAccessService instance = RecipeAccessService._();

  static const _deviceKey = 'foodgeniusai_free_recipe_used_v1_device';
  static const _legacyKey = 'foodgeniusai_free_recipe_used_v1';

  final AuthService _authService = AuthService();
  final GenerationLimitService _generationLimitService = GenerationLimitService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _accountKey(String uid) => 'foodgeniusai_free_recipe_used_v1_$uid';

  Future<RecipeAccessDecision> decide({String source = 'unknown'}) async {
    final subscribed = await hasPaidSubscription();
    final successfulRecipes = await _successfulRecipeCountHint();
    final freeUsed = await hasUsedFreeRecipe();

    RecipeAccessDecision decision;
    if (subscribed) {
      final status = await _generationLimitService.getStatus();
      if (status.remaining <= 0) {
        decision = RecipeAccessDecision.showPaywall;
        _log(
          'source=$source, successfulRecipes=$successfulRecipes, '
          'subscribed=true, remaining=${status.remaining}, decision=showPaywall',
        );
        return decision;
      }
      decision = RecipeAccessDecision.allowSubscription;
      _log(
        'source=$source, successfulRecipes=$successfulRecipes, '
        'subscribed=true, remaining=${status.remaining}, decision=allowSubscription',
      );
      return decision;
    }

    if (!freeUsed) {
      decision = RecipeAccessDecision.allowFree;
      _log(
        'source=$source, successfulRecipes=$successfulRecipes, '
        'subscribed=false, decision=allowFree',
      );
      return decision;
    }

    decision = RecipeAccessDecision.showPaywall;
    _log(
      'source=$source, successfulRecipes=$successfulRecipes, '
      'subscribed=false, decision=showPaywall',
    );
    return decision;
  }

  Future<bool> canGenerateRecipe({String source = 'unknown'}) async {
    final decision = await decide(source: source);
    return decision != RecipeAccessDecision.showPaywall;
  }

  Future<bool> shouldShowPaywall({String source = 'unknown'}) async {
    final decision = await decide(source: source);
    return decision == RecipeAccessDecision.showPaywall;
  }

  /// Throws [FreeRecipeLimitException] or [GenerationLimitException] when blocked.
  Future<void> assertCanGenerate({String source = 'unknown'}) async {
    if (await hasPaidSubscription()) {
      final status = await _generationLimitService.getStatus();
      if (status.remaining <= 0) {
        _log(
          'source=$source, subscribed=true, remaining=0, decision=showPaywall',
        );
        throw GenerationLimitException(
          'You\'ve used all ${status.limit} AI recipe generations for this month. '
          'Your limit resets at the start of next month.',
        );
      }
      _log(
        'source=$source, subscribed=true, remaining=${status.remaining}, '
        'decision=allowSubscription',
      );
      return;
    }

    if (await hasUsedFreeRecipe()) {
      _log(
        'source=$source, subscribed=false, decision=showPaywall',
      );
      throw const FreeRecipeLimitException();
    }

    _log(
      'source=$source, subscribed=false, decision=allowFree',
    );
  }

  Future<bool> hasPaidSubscription() async {
    final profile = await _authService.fetchUserProfile();
    return _authService.hasPaidSubscription(profile);
  }

  /// Free recipe is used only after a successful save (call from persist path).
  Future<void> recordSuccessfulGeneration({
    String source = 'unknown',
    required bool generationSucceeded,
  }) async {
    if (!generationSucceeded) {
      _log('generationFailed=true, freeRecipeConsumed=false, source=$source');
      return;
    }

    if (await hasPaidSubscription()) {
      try {
        await _generationLimitService.consumeGeneration();
        _log(
          'source=$source, subscribed=true, freeRecipeConsumed=false, '
          'paidCreditConsumed=true',
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[RecipeAccess] Paid generation limit sync failed: $error\n$stackTrace',
        );
      }
      return;
    }

    await _markFreeUsed();
    _log(
      'source=$source, subscribed=false, freeRecipeConsumed=true',
    );
  }

  /// Marks free recipe as consumed (local + account). Prefer
  /// [recordSuccessfulGeneration] for normal flows.
  Future<void> markFreeRecipeUsed() => _markFreeUsed();

  Future<bool> hasUsedFreeRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _authService.currentUser;

    // Device-level lock prevents reusing free quota via logout / new sessions.
    final deviceUsed = prefs.getBool(_deviceKey) == true ||
        prefs.getBool(_legacyKey) == true;
    if (deviceUsed) {
      // Migrate legacy key → device key.
      if (prefs.getBool(_legacyKey) == true &&
          prefs.getBool(_deviceKey) != true) {
        await prefs.setBool(_deviceKey, true);
      }
    }

    if (user != null && !user.isAnonymous) {
      final accountUsed = prefs.getBool(_accountKey(user.uid)) == true;
      if (accountUsed || deviceUsed) {
        return true;
      }

      final profile = await _authService.fetchUserProfile();
      if (profile != null) {
        final freeFlag = profile['freeRecipeUsed'] == true;
        final total = _asInt(profile['totalRecipesGenerated']);
        if (freeFlag || total > 0) {
          await prefs.setBool(_accountKey(user.uid), true);
          await prefs.setBool(_deviceKey, true);
          return true;
        }
      }
      return false;
    }

    // Anonymous / guest: device only (never infer from pending recipes).
    return deviceUsed;
  }

  Future<void> _markFreeUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceKey, true);
    await prefs.setBool(_legacyKey, true);

    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) return;

    await prefs.setBool(_accountKey(user.uid), true);
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'freeRecipeUsed': true,
        },
        SetOptions(merge: true),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[RecipeAccess] Failed to sync freeRecipeUsed: $error\n$stackTrace',
      );
    }
  }

  /// Debug-only: reset free-recipe test state for the current identity.
  /// Does not modify subscription fields (plan/tier/Stripe IDs).
  Future<void> resetFreeRecipeTest() async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceKey);
    await prefs.remove(_legacyKey);

    final user = _authService.currentUser;
    if (user != null && !user.isAnonymous) {
      await prefs.remove(_accountKey(user.uid));
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'freeRecipeUsed': false,
            // Developer-only: clear usage counters so free-trial tests work.
            // Does not touch subscriptionPlanId / Stripe fields.
            'totalRecipesGenerated': 0,
            'monthlyGenerationsUsed': 0,
          },
          SetOptions(merge: true),
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[RecipeAccess] Debug reset Firestore failed: $error\n$stackTrace',
        );
      }
    }

    _log('debugResetFreeRecipeTest=true');
  }

  Future<int> _successfulRecipeCountHint() async {
    final user = _authService.currentUser;
    if (user != null && !user.isAnonymous) {
      final profile = await _authService.fetchUserProfile();
      return _asInt(profile?['totalRecipesGenerated']);
    }
    final used = await hasUsedFreeRecipe();
    return used ? 1 : 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _log(String message) {
    debugPrint('[RecipeAccess] $message');
  }
}
