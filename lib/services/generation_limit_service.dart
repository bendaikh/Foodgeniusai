import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/cloud_function_http.dart';

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
      limit: cloudFunctionInt(data['limit']),
      used: cloudFunctionInt(data['used']),
      remaining: cloudFunctionInt(data['remaining']),
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
      final data = await _callFunction('getRecipeGenerationStatus');
      return GenerationLimitStatus.fromMap(data);
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
      final data = await _callFunction('consumeRecipeGeneration');
      return GenerationLimitStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Generation limit reached');
    }
  }

  Future<Map<String, dynamic>> _callFunction(String name) async {
    if (kIsWeb) {
      return CloudFunctionHttp.call(name);
    }

    final result = await _functions.httpsCallable(name).call();
    return Map<String, dynamic>.from(result.data as Map);
  }
}
