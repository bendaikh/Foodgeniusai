import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe_model.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/pending_recipe_store.dart';
import '../theme/app_theme.dart';
import '../utils/checkout_redirect.dart';
import 'user_auth_page.dart';

class PricingPage extends StatefulWidget {
  final RecipeModel? returnRecipe;

  const PricingPage({super.key, this.returnRecipe});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final AuthService _authService = AuthService();
  final CheckoutService _checkoutService = CheckoutService();
  String? _loadingTier;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.returnRecipe != null) {
      PendingRecipeStore.instance.save(widget.returnRecipe!);
    }
  }

  Future<void> _startPaidCheckout(String tier) async {
    if (!_authService.isAuthenticatedUser) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserAuthPage(isLogin: false),
        ),
      );
      return;
    }

    if (widget.returnRecipe != null) {
      await PendingRecipeStore.instance.save(widget.returnRecipe!);
    }

    setState(() {
      _loadingTier = tier;
      _errorMessage = null;
    });

    try {
      final checkoutUrl = await _checkoutService.startCheckout(tier: tier);
      await redirectToCheckout(checkoutUrl);
      if (!mounted) return;
      setState(() => _loadingTier = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete payment in your browser, then return to the app to view your unlocked recipe.',
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loadingTier = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildTitle(),
                if (widget.returnRecipe != null) ...[
                  const SizedBox(height: 16),
                  _buildRecipeBanner(),
                ],
                const SizedBox(height: 40),
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 24),
                ],
                isMobile
                    ? Column(
                        children: [
                          _buildPricingCard(
                            tier: 'pro',
                            icon: '💎',
                            title: 'Gourmet Pro',
                            price: '\$12',
                            period: '/ month',
                            features: const [
                              'Unlock full recipes instantly',
                              'Ultra-realistic AI images',
                              'Unlimited recipe portfolio',
                            ],
                            buttonText: 'Subscribe with DodoPayment',
                            isPopular: true,
                          ),
                          const SizedBox(height: 20),
                          _buildPricingCard(
                            tier: 'elite',
                            icon: '👑',
                            title: 'Michelin Elite',
                            price: '\$29',
                            period: '/ month',
                            features: const [
                              'Everything in Pro',
                              'Priority AI generation',
                              'Premium recipe precision',
                            ],
                            buttonText: 'Go Elite',
                            isPopular: false,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildPricingCard(
                              tier: 'pro',
                              icon: '💎',
                              title: 'Gourmet Pro',
                              price: '\$12',
                              period: '/ month',
                              features: const [
                                'Unlock full recipes instantly',
                                'Ultra-realistic AI images',
                                'Unlimited recipe portfolio',
                              ],
                              buttonText: 'Subscribe with DodoPayment',
                              isPopular: true,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildPricingCard(
                              tier: 'elite',
                              icon: '👑',
                              title: 'Michelin Elite',
                              price: '\$29',
                              period: '/ month',
                              features: const [
                                'Everything in Pro',
                                'Priority AI generation',
                                'Premium recipe precision',
                              ],
                              buttonText: 'Go Elite',
                              isPopular: false,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                Text(
                  _authService.isAuthenticatedUser
                      ? 'Signed in as ${FirebaseAuth.instance.currentUser?.email ?? 'your account'}'
                      : 'Sign in first, then choose a plan to unlock your recipe.',
                  style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Spacer(),
        if (widget.returnRecipe != null)
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu, color: AppTheme.primaryGreen),
            label: const Text(
              'Back to recipe preview',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Pick a plan and pay securely with DodoPayment. After payment, you\'ll return to your generated recipe fully unlocked.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecipeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Subscribe to unlock "${widget.returnRecipe!.title}"',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String tier,
    required String icon,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String buttonText,
    required bool isPopular,
  }) {
    final isLoading = _loadingTier == tier;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: const Center(
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading || _loadingTier != null
                        ? null
                        : () => _startPaidCheckout(tier),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payment),
                    label: Text(isLoading ? 'Redirecting…' : buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      foregroundColor:
                          isPopular ? AppTheme.darkBackground : Colors.white,
                      side: isPopular
                          ? null
                          : const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
}
