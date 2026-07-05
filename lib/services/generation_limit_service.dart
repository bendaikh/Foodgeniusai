import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GenerationLimitStatus {
  final int limit;
  final int used;
  final int remaining;
  final String tier;
  final String planId;

  const GenerationLimitStatus({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.tier,
    required this.planId,
  });

  factory GenerationLimitStatus.fromMap(Map<String, dynamic> data) {
    return GenerationLimitStatus(
      limit: (data['limit'] as num?)?.toInt() ?? 0,
      used: (data['used'] as num?)?.toInt() ?? 0,
      remaining: (data['remaining'] as num?)?.toInt() ?? 0,
      tier: data['tier'] as String? ?? 'free',
      planId: data['planId'] as String? ?? 'free',
    );
  }
}

class GenerationLimitService {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  bool get _shouldEnforce {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  Future<GenerationLimitStatus> getStatus() async {
    if (!_shouldEnforce) {
      return const GenerationLimitStatus(
        limit: 0,
        used: 0,
        remaining: 0,
        tier: 'guest',
        planId: 'guest',
      );
    }

    try {
      final result =
          await _functions.httpsCallable('getRecipeGenerationStatus').call();
      return GenerationLimitStatus.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to load generation status');
    }
  }

  Future<GenerationLimitStatus> consumeGeneration() async {
    if (!_shouldEnforce) {
      return const GenerationLimitStatus(
        limit: 0,
        used: 0,
        remaining: 0,
        tier: 'guest',
        planId: 'guest',
      );
    }

    try {
      final result =
          await _functions.httpsCallable('consumeRecipeGeneration').call();
      return GenerationLimitStatus.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Generation limit reached');
    }
  }
}
