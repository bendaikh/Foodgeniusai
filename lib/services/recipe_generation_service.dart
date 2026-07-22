import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'generation_usage_service.dart';
import 'pending_recipe_service.dart';
import 'recipe_access_service.dart';

/// Shared post-generation flow: save recipes and consume access credits.
class RecipeGenerationService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final RecipeAccessService _access = RecipeAccessService.instance;

  bool get isRegisteredUser {
    final user = _authService.currentUser;
    return user != null && !user.isAnonymous;
  }

  Future<bool> hasPaidSubscription() => _access.hasPaidSubscription();

  /// Throws when generation is not allowed (paid monthly limit or free quota).
  Future<void> ensureCanGenerate({String source = 'unknown'}) {
    return _access.assertCanGenerate(source: source);
  }

  /// Ensures a recipe appears in My Recipes for signed-in users.
  /// Guests are stored as pending until they create an account.
  ///
  /// Does **not** consume free/paid generation quota.
  Future<RecipeModel> ensureInMyRecipes(RecipeModel recipe) async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      await PendingRecipeService.instance.save(recipe);
      return recipe;
    }

    if (recipe.userId != user.uid &&
        recipe.userId != 'guest' &&
        recipe.userId.isNotEmpty) {
      throw Exception('This recipe belongs to another account.');
    }

    final recipeForUser = recipe.copyWith(userId: user.uid);
    final docId = await _firestoreService.createRecipe(recipeForUser);
    final savedRecipe = recipeForUser.copyWith(id: docId);

    await PendingRecipeService.instance.save(savedRecipe);

    try {
      await GenerationUsageService.recordIfNeeded(
        userId: user.uid,
        recipeId: docId,
      );
    } catch (error, stackTrace) {
      debugPrint('Generation credit tracking failed: $error\n$stackTrace');
    }

    return savedRecipe;
  }

  /// Saves a recipe, then records a successful generation (free or paid).
  Future<RecipeModel> persistGeneratedRecipe(
    RecipeModel recipe, {
    String source = 'unknown',
  }) async {
    try {
      final saved = await ensureInMyRecipes(recipe);
      await _access.recordSuccessfulGeneration(
        source: source,
        generationSucceeded: true,
      );
      return saved;
    } catch (e) {
      await _access.recordSuccessfulGeneration(
        source: source,
        generationSucceeded: false,
      );
      rethrow;
    }
  }

  /// Moves any pending/local/cloud recipe into My Recipes for the signed-in user.
  Future<RecipeModel?> syncPendingToMyRecipes() async {
    if (!isRegisteredUser) return null;

    try {
      return await PendingRecipeService.instance.claimAndPersist();
    } catch (error, stackTrace) {
      debugPrint('Pending recipe sync failed: $error\n$stackTrace');
      return null;
    }
  }

  /// Sync pending recipes, then fetch the user's saved recipes.
  Future<List<RecipeModel>> loadMyRecipes(String userId) async {
    final uid = _resolveRecipesUserId(userId);
    if (uid == null) return [];

    await syncPendingToMyRecipes();

    List<RecipeModel> recipes;
    try {
      recipes = await _firestoreService.fetchRecipesByUser(uid);
    } catch (error, stackTrace) {
      debugPrint('loadMyRecipes fetch failed: $error\n$stackTrace');
      recipes = [];
    }

    return _mergePendingRecipes(uid, recipes);
  }

  /// Prefer the signed-in user's uid so queries always match Firestore auth rules.
  String? _resolveRecipesUserId(String userId) {
    final user = _authService.currentUser;
    if (user != null && !user.isAnonymous) {
      return user.uid;
    }
    return userId.isNotEmpty ? userId : null;
  }

  /// Include local/cloud pending recipes that have not reached Firestore yet.
  List<RecipeModel> mergePendingRecipes(
    String userId,
    List<RecipeModel> recipes,
  ) {
    final uid = _resolveRecipesUserId(userId);
    if (uid == null) return recipes;
    return _mergePendingRecipes(uid, recipes);
  }

  List<RecipeModel> _mergePendingRecipes(
    String uid,
    List<RecipeModel> recipes,
  ) {
    final knownIds = recipes.map((r) => r.id).whereType<String>().toSet();
    final merged = List<RecipeModel>.from(recipes);

    final pending = PendingRecipeService.instance.loadLocal();
    if (pending != null && _pendingBelongsToUser(pending, uid)) {
      final pendingId = pending.id;
      if (pendingId == null ||
          pendingId.isEmpty ||
          !knownIds.contains(pendingId)) {
        merged.insert(0, pending.copyWith(userId: uid));
      }
    }

    merged.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return merged;
  }

  bool _pendingBelongsToUser(RecipeModel recipe, String uid) {
    return recipe.userId == uid ||
        recipe.userId == 'guest' ||
        recipe.userId.isEmpty;
  }
}
