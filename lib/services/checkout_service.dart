import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CheckoutService {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<String> startCheckout({required String planId, String? tier}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Please sign in before choosing a paid plan.');
    }

    final origin =
        kIsWeb ? Uri.base.origin : 'https://gourmetai-c432b.web.app';

    try {
      final result = await _functions.httpsCallable('createUserCheckout').call({
        'planId': planId,
        if (tier != null) 'tier': tier,
        'successUrl': '$origin/payment-success',
        'cancelUrl': '$origin/payment-cancel',
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final checkoutUrl = data['checkoutUrl'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Checkout URL was not returned by the server.');
      }
      return checkoutUrl;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to start checkout');
    }
  }

  Future<Map<String, dynamic>> completeCheckout({
    String? checkoutId,
    String? sessionId,
    String? tier,
    String? planId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Please sign in to complete your subscription.');
    }

    try {
      final result =
          await _functions.httpsCallable('completeUserCheckout').call({
        if (checkoutId != null) 'checkoutId': checkoutId,
        if (sessionId != null) 'sessionId': sessionId,
        if (tier != null) 'tier': tier,
        if (planId != null) 'planId': planId,
      });

      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to verify payment');
    }
  }
}
