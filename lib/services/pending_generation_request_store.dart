import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's recipe form request across the free-limit paywall.
class PendingGenerationRequest {
  final String source; // 'craving' | 'ingredients'
  final String craving;
  final String? mealType;
  final String? dietary;
  final int? servings;
  final String? portionSize;
  final List<String> ingredients;

  /// Standard Generate Recipe preferences.
  final String? mainGoal;
  final List<String> dietaryPreferences;
  final List<String> allergies;

  /// Scan Fridge optional preferences (ingredients source only).
  final String? cuisine;
  final String? cookingTime;
  final String? difficulty;
  final List<String> originalDetectedIngredients;

  const PendingGenerationRequest({
    required this.source,
    this.craving = '',
    this.mealType,
    this.dietary,
    this.servings,
    this.portionSize,
    this.ingredients = const [],
    this.mainGoal,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.cuisine,
    this.cookingTime,
    this.difficulty,
    this.originalDetectedIngredients = const [],
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'craving': craving,
        'mealType': mealType,
        'dietary': dietary,
        'servings': servings,
        'portionSize': portionSize,
        'ingredients': ingredients,
        'mainGoal': mainGoal,
        'dietaryPreferences': dietaryPreferences,
        'allergies': allergies,
        'cuisine': cuisine,
        'cookingTime': cookingTime,
        'difficulty': difficulty,
        'originalDetectedIngredients': originalDetectedIngredients,
      };

  factory PendingGenerationRequest.fromJson(Map<String, dynamic> json) {
    final dietaryPrefs = (json['dietaryPreferences'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final legacyDietary = json['dietary'] as String?;
    return PendingGenerationRequest(
      source: json['source'] as String? ?? 'craving',
      craving: json['craving'] as String? ?? '',
      mealType: json['mealType'] as String?,
      dietary: legacyDietary,
      servings: json['servings'] is int
          ? json['servings'] as int
          : int.tryParse('${json['servings'] ?? ''}'),
      portionSize: json['portionSize'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mainGoal: json['mainGoal'] as String?,
      dietaryPreferences: dietaryPrefs.isNotEmpty
          ? dietaryPrefs
          : (legacyDietary != null && legacyDietary.isNotEmpty
              ? <String>[legacyDietary]
              : const <String>[]),
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cuisine: json['cuisine'] as String?,
      cookingTime: json['cookingTime'] as String?,
      difficulty: json['difficulty'] as String?,
      originalDetectedIngredients:
          (json['originalDetectedIngredients'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
    );
  }
}

class PendingGenerationRequestStore {
  PendingGenerationRequestStore._();
  static final PendingGenerationRequestStore instance =
      PendingGenerationRequestStore._();

  static const _prefsKey = 'foodgeniusai_pending_generation_request_v1';

  Future<void> save(PendingGenerationRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(request.toJson()));
  }

  Future<PendingGenerationRequest?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return PendingGenerationRequest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
