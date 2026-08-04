import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'pending_image_completion_service.dart';
import 'pending_image_completion_store.dart';
import 'pending_recipe_service.dart';

/// Permanently deletes a user's own generated recipe.
///
/// Does **not** consume or refund generation quota.
/// Unsave is a separate action that only clears [RecipeModel.isSaved].
class RecipeDeletionService {
  RecipeDeletionService._();
  static final RecipeDeletionService instance = RecipeDeletionService._();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes [recipe] from Firestore history (and Saved, since it lives on the
  /// same document). Optionally removes the recipe image from Storage when it
  /// belongs to this user under `recipes/{uid}/`.
  ///
  /// Also clears local/cloud pending copies so [PendingRecipeService.claimAndPersist]
  /// cannot resurrect the recipe after deletion.
  Future<void> deleteOwnedRecipe(RecipeModel recipe) async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Sign in to delete recipes.');
    }

    final recipeId = recipe.id;
    if (recipeId == null || recipeId.isEmpty) {
      throw Exception('This recipe cannot be deleted.');
    }

    // Clear pending copies first so a mid-delete feed reload cannot recreate it.
    await _cleanupPendingForRecipe(recipe, user.uid);

    // Always re-read to enforce ownership and avoid stale client data.
    final existing = await _firestoreService.getRecipeById(recipeId);
    if (existing == null) {
      await _cleanupPendingForRecipe(recipe, user.uid);
      await _cleanupImageJobs(recipe);
      return;
    }

    if (existing.userId != user.uid) {
      throw Exception('You can only delete your own recipes.');
    }

    await _tryDeleteOwnedImage(
      imageUrl: existing.imageUrl,
      userId: user.uid,
    );

    await _firestoreService.deleteRecipe(recipeId);

    // Only treat delete as successful when the document is actually gone.
    final stillThere = await _firestoreService.getRecipeById(recipeId);
    if (stillThere != null) {
      throw Exception('Recipe could not be deleted. Please try again.');
    }

    await _cleanupPendingForRecipe(existing, user.uid);
    await _cleanupImageJobs(existing);
  }

  /// Clears local + cloud pending recipe when it refers to [recipe].
  ///
  /// Important: must use async pending load. Sync [PendingRecipeService.loadLocal]
  /// returns null before SharedPreferences is ready, which previously left the
  /// cloud pending doc intact so claimAndPersist recreated the deleted recipe.
  Future<void> _cleanupPendingForRecipe(RecipeModel recipe, String uid) async {
    try {
      final pending = await PendingRecipeService.instance.load();
      if (pending != null && _pendingMatchesRecipe(pending, recipe, uid)) {
        await PendingRecipeService.instance.clear();
        return;
      }

      // Cloud pending may still reference this recipe even if local load missed it.
      final doc =
          await _firestore.collection('pending_recipes').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data() ?? const <String, dynamic>{};
      final clientId =
          (data['clientId'] as String?) ?? (data['id'] as String?) ?? '';
      final title = (data['title'] as String?) ?? '';
      final matchesId =
          recipe.id != null && recipe.id!.isNotEmpty && clientId == recipe.id;
      final matchesTitle =
          title.isNotEmpty && title == recipe.title && recipe.title.isNotEmpty;

      if (matchesId || matchesTitle) {
        await PendingRecipeService.instance.clear();
      }
    } catch (e) {
      debugPrint('Pending cleanup after delete: $e');
      // Best-effort: still try a full clear if we own a matching pending.
      try {
        final pending = await PendingRecipeService.instance.load();
        if (pending != null && _pendingMatchesRecipe(pending, recipe, uid)) {
          await PendingRecipeService.instance.clear();
        }
      } catch (_) {}
    }
  }

  bool _pendingMatchesRecipe(
    RecipeModel pending,
    RecipeModel recipe,
    String uid,
  ) {
    final belongs = pending.userId == uid ||
        pending.userId == 'guest' ||
        pending.userId.isEmpty;
    if (!belongs) return false;

    if (recipe.id != null &&
        recipe.id!.isNotEmpty &&
        pending.id == recipe.id) {
      return true;
    }

    return pending.title.isNotEmpty && pending.title == recipe.title;
  }

  Future<void> _cleanupImageJobs(RecipeModel recipe) async {
    final imageJob = await PendingImageCompletionStore.instance.load();
    if (imageJob != null &&
        PendingImageCompletionService.instance
            .matchesRecipe(imageJob, recipe)) {
      await PendingImageCompletionService.instance.clearPending();
    }
  }

  Future<void> _tryDeleteOwnedImage({
    required String? imageUrl,
    required String userId,
  }) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    if (!_looksLikeOwnedRecipeStorageUrl(imageUrl, userId)) return;

    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      final path = ref.fullPath;
      if (!path.startsWith('recipes/$userId/')) {
        debugPrint('Skipping image delete; path not owned: $path');
        return;
      }
      await ref.delete();
    } on FirebaseException catch (e) {
      // Object already missing is OK.
      if (e.code == 'object-not-found' || e.code == 'not-found') return;
      debugPrint('Recipe image delete skipped: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Recipe image delete skipped: $e');
    }
  }

  bool _looksLikeOwnedRecipeStorageUrl(String url, String userId) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isFirebaseHost = host.contains('firebasestorage.googleapis.com') ||
          host.contains('storage.googleapis.com');
      if (!isFirebaseHost) return false;

      final decoded = Uri.decodeFull(url);
      return decoded.contains('recipes/$userId/') ||
          decoded.contains('recipes%2F$userId%2F') ||
          decoded.contains('recipes%2F${Uri.encodeComponent(userId)}%2F');
    } catch (_) {
      return false;
    }
  }
}
