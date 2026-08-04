import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../exceptions/generation_limit_exception.dart';
import '../utils/cloud_function_http.dart';

/// Server-backed monthly quota status (recipe generations or fridge scans).
class QuotaStatus {
  final bool unlimited;
  final int? limit;
  final int used;
  final int? remaining;
  final String tier;
  final String planId;

  const QuotaStatus({
    required this.unlimited,
    required this.limit,
    required this.used,
    required this.remaining,
    required this.tier,
    required this.planId,
  });

  bool get hasRemaining => unlimited || (remaining ?? 0) > 0;

  String get remainingLabel {
    if (unlimited) return 'Unlimited';
    final rem = remaining ?? 0;
    final lim = limit ?? 0;
    return '$rem / $lim';
  }

  factory QuotaStatus.fromMap(Map<String, dynamic> data) {
    final unlimited = data['unlimited'] == true;
    if (unlimited) {
      return QuotaStatus(
        unlimited: true,
        limit: null,
        used: cloudFunctionInt(data['used']),
        remaining: null,
        tier: data['tier'] as String? ?? 'free',
        planId: data['planId'] as String? ?? 'free',
      );
    }

    return QuotaStatus(
      unlimited: false,
      limit: cloudFunctionInt(data['limit']),
      used: cloudFunctionInt(data['used']),
      remaining: cloudFunctionInt(data['remaining']),
      tier: data['tier'] as String? ?? 'free',
      planId: data['planId'] as String? ?? 'free',
    );
  }

  factory QuotaStatus.blockedGuest() {
    return const QuotaStatus(
      unlimited: false,
      limit: 0,
      used: 0,
      remaining: 0,
      tier: 'guest',
      planId: 'guest',
    );
  }
}

/// Alias kept for existing call sites.
typedef GenerationLimitStatus = QuotaStatus;

class GenerationLimitService {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  bool get _shouldEnforce {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  Future<QuotaStatus> getStatus() async {
    if (!_shouldEnforce) return QuotaStatus.blockedGuest();

    try {
      final data = await _callFunction('getRecipeGenerationStatus');
      return QuotaStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to load generation status');
    }
  }

  Future<QuotaStatus> consumeGeneration() async {
    if (!_shouldEnforce) return QuotaStatus.blockedGuest();

    try {
      final data = await _callFunction('consumeRecipeGeneration');
      return QuotaStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Generation limit reached');
    }
  }

  Future<QuotaStatus> getFridgeScanStatus() async {
    if (!_shouldEnforce) return QuotaStatus.blockedGuest();

    try {
      final data = await _callFunction('getFridgeScanStatus');
      return QuotaStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to load Fridge Scan status');
    }
  }

  Future<QuotaStatus> consumeFridgeScan() async {
    if (!_shouldEnforce) return QuotaStatus.blockedGuest();

    try {
      final data = await _callFunction('consumeFridgeScan');
      return QuotaStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? 'Fridge Scan limit reached';
      if (e.code == 'resource-exhausted' ||
          message.contains('Fridge Scan') ||
          message.contains('used all')) {
        throw FridgeScanLimitException(message);
      }
      throw Exception(message);
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
