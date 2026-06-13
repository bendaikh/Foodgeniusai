import 'dart:convert';

import '../models/recipe_model.dart';

const _storageKey = 'foodgeniusai_pending_recipe_v1';

/// No-op on non-web platforms.
class PendingRecipeStore {
  static final PendingRecipeStore instance = PendingRecipeStore._();
  PendingRecipeStore._();

  Future<void> save(RecipeModel recipe) async {}

  RecipeModel? load() => null;

  Future<void> clear() async {}
}

String encodeRecipe(RecipeModel recipe) => jsonEncode(recipe.toJson());

RecipeModel? decodeRecipe(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return RecipeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
