import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe_model.dart';
import '../services/checkout_service.dart';
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
  String? _error;
  bool _isProcessing = true;

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

  Future<void> _handlePaymentSuccess() async {
    final params = _queryParams();
    final checkoutId = params['checkout_id'] ??
        params['checkoutId'] ??
        params['session_id'] ??
        params['sessionId'] ??
        params['id'];
    final tier = params['tier'];

    try {
      await FirebaseAuth.instance.authStateChanges().first;

      Object? lastError;
      for (var attempt = 0; attempt < 4; attempt++) {
        try {
          await _checkoutService.completeCheckout(
            checkoutId: checkoutId,
            sessionId: checkoutId,
            tier: tier,
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

      if (lastError != null) {
        throw lastError!;
      }

      final recipe = PendingRecipeStore.instance.load();
      if (!mounted) return;

      if (recipe != null) {
        await PendingRecipeStore.instance.clear();
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 56,
                    ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
