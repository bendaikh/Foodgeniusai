import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/pending_checkout_store.dart';
import '../services/pending_recipe_store.dart';
import '../theme/app_theme.dart';
import 'auth_wrapper.dart';
import 'landing_page.dart';
import 'recipe_detail_page.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final CheckoutService _checkoutService = CheckoutService();
  final AuthService _authService = AuthService();
  String? _error;
  bool _isProcessing = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _handlePaymentSuccess();
  }

  Map<String, String> _queryParams() {
    if (kIsWeb) {
      return Uri.base.queryParameters;
    }
    return {};
  }

  bool get _isMobileCallback {
    final source = _queryParams()['source'];
    return source == 'mobile';
  }

  Future<void> _waitForActiveSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var attempt = 0; attempt < 15; attempt++) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (_authService.hasPaidSubscription(doc.data())) {
        return;
      }
      await Future.delayed(Duration(milliseconds: 400 + (attempt * 100)));
    }
  }

  Future<void> _handlePaymentSuccess() async {
    final params = _queryParams();
    final storedCheckoutId = await PendingCheckoutStore.instance.load();
    final checkoutId = params['checkout_id'] ??
        params['checkoutId'] ??
        params['session_id'] ??
        params['sessionId'] ??
        storedCheckoutId;
    final paymentId = params['payment_id'] ?? params['paymentId'];
    final subscriptionId =
        params['subscription_id'] ?? params['subscriptionId'];
    final status = params['status'];
    final planId = params['planId'] ?? params['tier'];

    setState(() {
      _isProcessing = true;
      _error = null;
      _isSuccess = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.isAnonymous) {
        Object? lastError;
        for (var attempt = 0; attempt < 4; attempt++) {
          try {
            await _checkoutService.completeCheckout(
              checkoutId: checkoutId,
              sessionId: checkoutId,
              paymentId: paymentId,
              subscriptionId: subscriptionId,
              status: status,
              planId: planId,
              tier: planId,
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

        if (lastError != null && !_isMobileCallback) {
          throw lastError;
        }

        await _waitForActiveSubscription();
      }

      await PendingCheckoutStore.instance.clear();
      if (!mounted) return;

      if (_isMobileCallback) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        return;
      }

      final recipe = PendingRecipeStore.instance.load();
      if (recipe != null) {
        await PendingRecipeStore.instance.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
          (route) => false,
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
        _isSuccess = false;
      });
    }
  }

  Future<void> _openRecipeAnyway() async {
    final recipe = PendingRecipeStore.instance.load();
    await PendingRecipeStore.instance.clear();
    if (!mounted) return;

    if (recipe != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0F2A3D),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _isMobileCallback
                    ? _buildMobileCallbackContent()
                    : _buildWebCallbackContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCallbackContent() {
    if (_isProcessing) {
      return _buildStatusCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Confirming your payment…',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we activate your subscription.',
              style: TextStyle(color: AppTheme.greyText, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isSuccess) {
      return _buildStatusCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your subscription has been activated successfully.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'You can now close this page and return to the GourmetAI mobile app to continue using all premium features.',
              style: TextStyle(
                color: AppTheme.greyText,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.smartphone, color: AppTheme.primaryGreen, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Switch back to the GourmetAI app — your premium access is ready.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildStatusCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 56),
          const SizedBox(height: 20),
          Text(
            _error ?? 'Something went wrong.',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handlePaymentSuccess,
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
          const Text(
            'If payment went through, close this page and return to the app — your subscription may already be active.',
            style: TextStyle(color: AppTheme.greyText, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWebCallbackContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isProcessing) ...[
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 24),
          const Text(
            'Confirming your payment…',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unlocking your recipe now.',
            style: TextStyle(color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Icon(Icons.error_outline, color: Colors.orange, size: 56),
          const SizedBox(height: 20),
          Text(
            _error ?? 'Something went wrong.',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handlePaymentSuccess,
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _openRecipeAnyway,
            child: const Text('Go to my recipe'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}
