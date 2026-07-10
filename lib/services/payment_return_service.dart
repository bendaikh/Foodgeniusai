import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/payment_config.dart';
import 'checkout_service.dart';
import 'pending_checkout_store.dart';

/// Completes mobile checkout when the user returns from the external browser
/// or opens the app via a payment deep link.
class PaymentReturnService {
  PaymentReturnService._();
  static final PaymentReturnService instance = PaymentReturnService._();

  final CheckoutService _checkoutService = CheckoutService();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isHandling = false;

  Future<void> initialize() async {
    if (kIsWeb) return;

    _linkSubscription ??= _appLinks.uriLinkStream.listen(_handleDeepLink);

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  Future<void> handleAppResumed() async {
    if (kIsWeb) return;
    await _completePendingCheckout();
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (kIsWeb) return;
    if (uri.scheme != PaymentConfig.appDeepLinkScheme) return;
    if (uri.host != PaymentConfig.appDeepLinkHost) return;

    final path = uri.path.replaceFirst(RegExp(r'^/'), '');
    if (path == 'cancel') {
      await PendingCheckoutStore.instance.clear();
      return;
    }

    if (path == 'success') {
      await _completePendingCheckout(queryParams: uri.queryParameters);
    }
  }

  Future<void> _completePendingCheckout({
    Map<String, String>? queryParams,
  }) async {
    if (_isHandling) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final params = queryParams ?? const <String, String>{};
    final storedCheckoutId = await PendingCheckoutStore.instance.load();
    final checkoutId = params['checkout_id'] ??
        params['checkoutId'] ??
        params['session_id'] ??
        params['sessionId'] ??
        storedCheckoutId;

    if (checkoutId == null || checkoutId.isEmpty) return;

    _isHandling = true;
    try {
      Object? lastError;
      for (var attempt = 0; attempt < 4; attempt++) {
        try {
          await _checkoutService.completeCheckout(
            checkoutId: checkoutId,
            sessionId: checkoutId,
            paymentId: params['payment_id'] ?? params['paymentId'],
            subscriptionId:
                params['subscription_id'] ?? params['subscriptionId'],
            status: params['status'],
            planId: params['planId'] ?? params['tier'],
            tier: params['planId'] ?? params['tier'],
          );
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2 + attempt));
          }
        }
      }

      if (lastError == null) {
        await PendingCheckoutStore.instance.clear();
      }
    } finally {
      _isHandling = false;
    }
  }
}
