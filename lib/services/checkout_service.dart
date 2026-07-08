import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/cloud_function_http.dart';
import 'pending_checkout_store.dart';

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

    final mobileSource = kIsWeb ? '' : '?source=mobile';
    final successUrl = '$origin/payment-success$mobileSource';
    final cancelUrl = '$origin/payment-cancel$mobileSource';

    try {
      final data = await _callFunction(
        'createUserCheckout',
        {
          'planId': planId,
          if (tier != null) 'tier': tier,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      final checkoutUrl = data['checkoutUrl'] as String?;
      final checkoutId = data['checkoutId'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Checkout URL was not returned by the server.');
      }
      if (checkoutId != null && checkoutId.isNotEmpty) {
        await PendingCheckoutStore.instance.save(checkoutId);
      }
      return checkoutUrl;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to start checkout');
    }
  }

  Future<Map<String, dynamic>> completeCheckout({
    String? checkoutId,
    String? sessionId,
    String? paymentId,
    String? subscriptionId,
    String? status,
    String? tier,
    String? planId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Please sign in to complete your subscription.');
    }

    try {
      return await _callFunction(
        'completeUserCheckout',
        {
          if (checkoutId != null) 'checkoutId': checkoutId,
          if (sessionId != null) 'sessionId': sessionId,
          if (paymentId != null) 'paymentId': paymentId,
          if (subscriptionId != null) 'subscriptionId': subscriptionId,
          if (status != null) 'status': status,
          if (tier != null) 'tier': tier,
          if (planId != null) 'planId': planId,
        },
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to verify payment');
    }
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    if (kIsWeb) {
      return CloudFunctionHttp.call(name, data: data);
    }

    final result = await _functions.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }
}
