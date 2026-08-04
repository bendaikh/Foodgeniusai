import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks a recipe that was saved without its image yet (background-safe).
class PendingImageJob {
  final String? recipeId;
  final String title;
  final String cuisine;
  final String userId;
  final String source;
  final int attempts;
  final String clientKey;

  const PendingImageJob({
    required this.title,
    required this.cuisine,
    required this.userId,
    required this.source,
    this.recipeId,
    this.attempts = 0,
    required this.clientKey,
  });

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'title': title,
        'cuisine': cuisine,
        'userId': userId,
        'source': source,
        'attempts': attempts,
        'clientKey': clientKey,
      };

  factory PendingImageJob.fromJson(Map<String, dynamic> json) {
    return PendingImageJob(
      recipeId: json['recipeId'] as String?,
      title: json['title'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      userId: json['userId'] as String? ?? 'guest',
      source: json['source'] as String? ?? 'unknown',
      attempts: json['attempts'] as int? ?? 0,
      clientKey: json['clientKey'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  PendingImageJob copyWith({int? attempts, String? recipeId}) {
    return PendingImageJob(
      recipeId: recipeId ?? this.recipeId,
      title: title,
      cuisine: cuisine,
      userId: userId,
      source: source,
      attempts: attempts ?? this.attempts,
      clientKey: clientKey,
    );
  }
}

/// SharedPreferences store for in-flight image completion after text persist.
class PendingImageCompletionStore {
  PendingImageCompletionStore._();
  static final PendingImageCompletionStore instance =
      PendingImageCompletionStore._();

  static const _prefsKey = 'foodgeniusai_pending_image_completion_v1';

  Future<void> save(PendingImageJob job) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(job.toJson()));
  }

  Future<PendingImageJob?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return PendingImageJob.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
