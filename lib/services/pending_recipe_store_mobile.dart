import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe_model.dart';
import 'pending_recipe_store_stub.dart' show decodeRecipe;

const _storageKey = 'foodgeniusai_pending_recipe_v1';

class PendingRecipeStore {
  static final PendingRecipeStore instance = PendingRecipeStore._();
  PendingRecipeStore._();

  SharedPreferences? _prefs;

  Future<void> _ensureReady() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> save(RecipeModel recipe) async {
    await _ensureReady();
    await _prefs!.setString(_storageKey, jsonEncode(recipe.toJson()));
  }

  RecipeModel? load() {
    final raw = _prefs?.getString(_storageKey);
    return decodeRecipe(raw);
  }

  Future<RecipeModel?> loadAsync() async {
    await _ensureReady();
    return load();
  }

  Future<void> clear() async {
    await _ensureReady();
    await _prefs!.remove(_storageKey);
  }
}
