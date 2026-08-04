import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';
import 'ai_settings_service.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'openai_service.dart';
import 'pending_image_completion_store.dart';
import 'pending_recipe_service.dart';

/// Completes missing recipe images after text has already been persisted.
///
/// Does **not** consume generation quota. Safe to call on app resume.
class PendingImageCompletionService {
  PendingImageCompletionService._();
  static final PendingImageCompletionService instance =
      PendingImageCompletionService._();

  static const maxAttempts = 3;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final AISettingsService _settingsService = AISettingsService();

  Future<void>? _inFlight;

  Future<PendingImageJob?> loadPending() =>
      PendingImageCompletionStore.instance.load();

  Future<void> clearPending() => PendingImageCompletionStore.instance.clear();

  /// Marks a persisted recipe as awaiting image completion.
  Future<void> enqueueForRecipe(
    RecipeModel recipe, {
    required String source,
  }) async {
    final job = PendingImageJob(
      recipeId: recipe.id,
      title: recipe.title,
      cuisine: recipe.cuisine,
      userId: recipe.userId,
      source: source,
      attempts: 0,
      clientKey:
          '${recipe.id ?? recipe.title}_${DateTime.now().millisecondsSinceEpoch}',
    );
    await PendingImageCompletionStore.instance.save(job);
  }

  /// Generates the image and attaches it to Firestore / pending local recipe.
  ///
  /// Returns the image URL on success, or null if generation failed (job kept).
  Future<String?> completeForRecipe({
    required RecipeModel recipe,
    required OpenAIService openai,
    required String source,
  }) async {
    final job = PendingImageJob(
      recipeId: recipe.id,
      title: recipe.title,
      cuisine: recipe.cuisine,
      userId: recipe.userId,
      source: source,
      attempts: 0,
      clientKey:
          '${recipe.id ?? recipe.title}_${DateTime.now().millisecondsSinceEpoch}',
    );
    await PendingImageCompletionStore.instance.save(job);

    if (_inFlight != null) {
      await _inFlight;
      final existing = await _existingImageUrl(job);
      if (existing != null && existing.isNotEmpty) return existing;
    }

    late final Future<String?> future;
    future = _runJob(job: job, openai: openai);
    _inFlight = future.whenComplete(() => _inFlight = null);
    return future;
  }

  /// Called on app resume / cold start to finish a pending image without
  /// regenerating recipe text or consuming quota.
  Future<String?> resumePendingIfNeeded() async {
    if (_inFlight != null) {
      await _inFlight;
      final job = await loadPending();
      if (job == null) {
        // Cleared by the in-flight run — try to read image from recipe.
        return null;
      }
    }

    final job = await loadPending();
    if (job == null) return null;
    if (job.title.trim().isEmpty) {
      await clearPending();
      return null;
    }
    if (job.attempts >= maxAttempts) {
      debugPrint(
        'Pending image completion abandoned after ${job.attempts} attempts',
      );
      await clearPending();
      return null;
    }

    // Already has an image? Clear and exit.
    final existingUrl = await _existingImageUrl(job);
    if (existingUrl != null && existingUrl.isNotEmpty) {
      await clearPending();
      return existingUrl;
    }

    late final Future<String?> future;
    future = () async {
      try {
        final settings = await _settingsService.getSettings();
        if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
          return null;
        }
        final openai = OpenAIService(settings);
        return _runJob(job: job, openai: openai);
      } catch (e, st) {
        debugPrint('Pending image resume failed: $e\n$st');
        return null;
      }
    }();

    _inFlight = future.whenComplete(() => _inFlight = null);
    return future;
  }

  Future<String?> _runJob({
    required PendingImageJob job,
    required OpenAIService openai,
  }) async {
    final bumped = job.copyWith(attempts: job.attempts + 1);
    await PendingImageCompletionStore.instance.save(bumped);

    try {
      final imageUrl = await openai.generateRecipeImage(
        job.title,
        'Professional food photography, high quality, well-lit, appetizing ${job.cuisine} cuisine dish, restaurant presentation, realistic, natural lighting, detailed texture',
        userId: job.userId.isEmpty ? 'guest' : job.userId,
      );

      await _attachImageUrl(
        recipeId: job.recipeId,
        userId: job.userId,
        title: job.title,
        imageUrl: imageUrl,
      );
      await clearPending();
      return imageUrl;
    } catch (e, st) {
      debugPrint('Image completion attempt ${bumped.attempts} failed: $e\n$st');
      if (bumped.attempts >= maxAttempts) {
        await clearPending();
      }
      return null;
    }
  }

  Future<String?> _existingImageUrl(PendingImageJob job) async {
    final recipeId = job.recipeId;
    if (recipeId != null && recipeId.isNotEmpty) {
      final user = _authService.currentUser;
      if (user != null && !user.isAnonymous) {
        final recipe = await _firestoreService.getRecipeById(recipeId);
        final url = recipe?.imageUrl;
        if (url != null && url.isNotEmpty) return url;
      }
    }

    final pending = PendingRecipeService.instance.loadLocal();
    if (pending != null &&
        (pending.id == job.recipeId || pending.title == job.title)) {
      final url = pending.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  Future<void> _attachImageUrl({
    required String? recipeId,
    required String userId,
    required String title,
    required String imageUrl,
  }) async {
    final user = _authService.currentUser;
    if (user != null &&
        !user.isAnonymous &&
        recipeId != null &&
        recipeId.isNotEmpty) {
      await _firestoreService.updateRecipe(recipeId, {'imageUrl': imageUrl});
    }

    final pending = PendingRecipeService.instance.loadLocal();
    if (pending != null &&
        (pending.id == recipeId ||
            (pending.title == title &&
                (pending.userId == userId ||
                    pending.userId == 'guest' ||
                    pending.userId.isEmpty)))) {
      await PendingRecipeService.instance.save(
        pending.copyWith(imageUrl: imageUrl),
      );
    }
  }

  bool matchesRecipe(PendingImageJob job, RecipeModel recipe) {
    if (job.recipeId != null &&
        recipe.id != null &&
        job.recipeId == recipe.id) {
      return true;
    }
    return job.title == recipe.title;
  }
}
