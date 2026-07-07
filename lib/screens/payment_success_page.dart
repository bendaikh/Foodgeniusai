import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/pending_checkout_store.dart';
import '../services/pending_recipe_service.dart';
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
  RecipeModel? _claimedRecipe;

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

  Future<void> _claimPendingRecipe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipe = await PendingRecipeService.instance.claimAndPersist(
      userId: user.uid,
    );
    if (!mounted) return;
    setState(() => _claimedRecipe = recipe);
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
      _claimedRecipe = null;
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
        await _claimPendingRecipe();
      }

      await PendingCheckoutStore.instance.clear();
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
        _isSuccess = false;
      });
    }
  }

  Future<void> _openRecipe() async {
    var recipe = _claimedRecipe;
    recipe ??= await PendingRecipeService.instance.claimAndPersist();

    if (!mounted) return;

    if (recipe != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe!),
        ),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
  }

  void _goHome() {
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
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              'Payment Successful!',
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
            Text(
              _isMobileCallback
                  ? 'You can now close this window and return to the Gourmet AI app.'
                  : 'You can now close this window and return to the Gourmet AI app, or continue below.',
              style: const TextStyle(
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
              child: Row(
                children: [
                  Icon(
                    _isMobileCallback ? Icons.smartphone : Icons.check_circle_outline,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isMobileCallback
                          ? 'Switch back to the Gourmet AI app — your premium access is ready.'
                          : 'Your premium access is active. ${_claimedRecipe != null ? 'Your generated recipe is saved and ready.' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isMobileCallback) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _claimedRecipe != null ? _openRecipe : _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _claimedRecipe != null ? 'View your recipe' : 'Continue to app',
                  ),
                ),
              ),
            ],
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
          Text(
            _isMobileCallback
                ? 'If payment went through, close this window and return to the app — your subscription may already be active.'
                : 'If payment went through, your subscription may already be active.',
            style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!_isMobileCallback) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openRecipe,
              child: const Text('Go to my recipe'),
            ),
          ],
        ],
      ),
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
