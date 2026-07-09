import 'dart:convert';
import 'dart:html' as html;

import '../models/recipe_model.dart';

const _storageKey = 'foodgeniusai_pending_recipe_v1';

class PendingRecipeStore {
  static final PendingRecipeStore instance = PendingRecipeStore._();
  PendingRecipeStore._();

  Future<void> save(RecipeModel recipe) async {
    final encoded = jsonEncode(recipe.toJson());
    html.window.sessionStorage[_storageKey] = encoded;
    // localStorage survives checkout redirects and browser back navigation.
    html.window.localStorage[_storageKey] = encoded;
  }

  RecipeModel? load() {
    final raw = html.window.sessionStorage[_storageKey] ??
        html.window.localStorage[_storageKey];
    return decodeRecipe(raw);
  }

  Future<RecipeModel?> loadAsync() async => load();

  Future<void> clear() async {
    html.window.sessionStorage.remove(_storageKey);
    html.window.localStorage.remove(_storageKey);
  }
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
