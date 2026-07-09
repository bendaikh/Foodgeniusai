import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe_model.dart';
import '../utils/firestore_recipe_data.dart';
import 'firestore_service.dart';
import 'generation_usage_service.dart';
import 'pending_recipe_store.dart';

/// Persists guest recipes across signup, payment redirect, and mobile browser checkout.
class PendingRecipeService {
  static final PendingRecipeService instance = PendingRecipeService._();
  PendingRecipeService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static const _cloudCollection = 'pending_recipes';

  Future<void> save(RecipeModel recipe) async {
    await PendingRecipeStore.instance.save(recipe);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    await _firestore.collection(_cloudCollection).doc(user.uid).set({
      ...recipe.toJson(),
      'clientId': recipe.id,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<RecipeModel?> load() async {
    final local = await _loadLocal();
    if (local != null) return local;

    return _loadFromCloud();
  }

  RecipeModel? loadLocal() {
    return PendingRecipeStore.instance.load();
  }

  Future<RecipeModel?> _loadLocal() async {
    try {
      return await PendingRecipeStore.instance.loadAsync();
    } catch (_) {
      return PendingRecipeStore.instance.load();
    }
  }

  Future<RecipeModel?> _loadFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return null;

    try {
      final doc =
          await _firestore.collection(_cloudCollection).doc(user.uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data.remove('savedAt');
      data.remove('clientId');
      return RecipeModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> syncLocalToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final local = await _loadLocal();
    if (local == null) return;

    await save(local);
  }

  Future<void> clear() async {
    await PendingRecipeStore.instance.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      await _firestore.collection(_cloudCollection).doc(user.uid).delete();
    } catch (_) {}
  }

  /// Saves the pending recipe to the user's recipe history and clears pending storage.
  /// Idempotent: skips if the recipe was already claimed (e.g. by webhook).
  Future<RecipeModel?> claimAndPersist({String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    var recipe = await load();
    if (recipe == null) {
      recipe = await _loadClaimedRecipeFromHistory(uid);
      if (recipe != null) {
        await clear();
      }
      return recipe;
    }

    final clientId = recipe.id;
    if (clientId != null && clientId.isNotEmpty) {
      try {
        final existing =
            await _firestore.collection('recipes').doc(clientId).get();
        if (existing.exists) {
          final existingUserId =
              existing.data()?['userId'] as String? ?? '';
          if (existingUserId == uid) {
            await clear();
            return RecipeModel.fromFirestore(existing);
          }
        }
      } catch (_) {}
    }

    final recipeForUser = RecipeModel(
      id: clientId,
      userId: uid,
      title: recipe.title,
      description: recipe.description,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      nutrition: recipe.nutrition,
      difficulty: recipe.difficulty,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      totalTime: recipe.totalTime,
      servings: recipe.servings,
      cuisine: recipe.cuisine,
      mealType: recipe.mealType,
      dietary: recipe.dietary,
      imageUrl: recipe.imageUrl,
      createdAt: recipe.createdAt ?? DateTime.now(),
      views: recipe.views,
      saves: recipe.saves,
      isPublic: recipe.isPublic,
    );

    try {
      RecipeModel? savedRecipe;
      final data = sanitizeRecipeForFirestore(recipeForUser.toMap());

      if (clientId != null && clientId.isNotEmpty) {
        final docRef = _firestore.collection('recipes').doc(clientId);
        final existing = await docRef.get();
        if (existing.exists) {
          final existingUserId =
              existing.data()?['userId'] as String? ?? '';
          if (existingUserId == uid) {
            await docRef.update(data);
            savedRecipe = recipeForUser.copyWith(id: clientId);
          } else {
            final docId = await _firestoreService.createRecipe(
              recipeForUser.copyWith(id: null),
            );
            savedRecipe = recipeForUser.copyWith(id: docId);
          }
        } else {
          await docRef.set(data);
          savedRecipe = recipeForUser.copyWith(id: clientId);
        }
      } else {
        final docId = await _firestoreService.createRecipe(recipeForUser);
        savedRecipe = recipeForUser.copyWith(id: docId);
      }

      if (savedRecipe.id != null && savedRecipe.id!.isNotEmpty) {
        await GenerationUsageService.recordIfNeeded(
          userId: uid,
          recipeId: savedRecipe.id!,
        );
      }

      await clear();
      return savedRecipe;
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('claimAndPersist failed: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<RecipeModel?> _loadClaimedRecipeFromHistory(String uid) async {
    try {
      final pendingDoc =
          await _firestore.collection(_cloudCollection).doc(uid).get();
      if (!pendingDoc.exists) return null;

      final clientId = pendingDoc.data()?['clientId'] as String? ??
          pendingDoc.data()?['id'] as String?;
      if (clientId == null || clientId.isEmpty) return null;

      final recipeDoc =
          await _firestore.collection('recipes').doc(clientId).get();
      if (!recipeDoc.exists) return null;
      return RecipeModel.fromFirestore(recipeDoc);
    } catch (_) {
      return null;
    }
  }
}

extension RecipeModelCopyWith on RecipeModel {
  RecipeModel copyWith({String? id, String? userId}) {
    return RecipeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title,
      description: description,
      ingredients: ingredients,
      instructions: instructions,
      nutrition: nutrition,
      difficulty: difficulty,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings,
      cuisine: cuisine,
      mealType: mealType,
      dietary: dietary,
      imageUrl: imageUrl,
      createdAt: createdAt,
      views: views,
      saves: saves,
      isPublic: isPublic,
    );
  }
}
