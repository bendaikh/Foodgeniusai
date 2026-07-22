import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's recipe form request across the free-limit paywall.
class PendingGenerationRequest {
  final String source; // 'craving' | 'ingredients'
  final String craving;
  final String? mealType;
  final String? dietary;
  final int servings;
  final String? portionSize;
  final List<String> ingredients;

  const PendingGenerationRequest({
    required this.source,
    this.craving = '',
    this.mealType,
    this.dietary,
    this.servings = 2,
    this.portionSize,
    this.ingredients = const [],
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'craving': craving,
        'mealType': mealType,
        'dietary': dietary,
        'servings': servings,
        'portionSize': portionSize,
        'ingredients': ingredients,
      };

  factory PendingGenerationRequest.fromJson(Map<String, dynamic> json) {
    return PendingGenerationRequest(
      source: json['source'] as String? ?? 'craving',
      craving: json['craving'] as String? ?? '',
      mealType: json['mealType'] as String?,
      dietary: json['dietary'] as String?,
      servings: json['servings'] as int? ?? 2,
      portionSize: json['portionSize'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
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
