import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe_model.dart';
import '../models/subscription_plan_model.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/pending_recipe_store.dart';
import '../services/subscription_plan_service.dart';
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
  final SubscriptionPlanService _planService = SubscriptionPlanService();
  String? _loadingPlanId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.returnRecipe != null) {
      PendingRecipeStore.instance.save(widget.returnRecipe!);
    }
  }

  Future<void> _startPaidCheckout(SubscriptionPlanModel plan) async {
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
      _loadingPlanId = plan.id;
      _errorMessage = null;
    });

    try {
      final checkoutUrl = await _checkoutService.startCheckout(planId: plan.id);
      await redirectToCheckout(checkoutUrl);
      if (!mounted) return;
      setState(() => _loadingPlanId = null);
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
        _loadingPlanId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<SubscriptionPlanModel>>(
          stream: _planService.watchActivePlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final plans = snapshot.data ?? [];

            return SingleChildScrollView(
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
                    if (plans.isEmpty)
                      _buildEmptyState()
                    else
                      _buildPlansGrid(plans, isMobile),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlansGrid(List<SubscriptionPlanModel> plans, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            _buildPricingCard(plans[i]),
            if (i < plans.length - 1) const SizedBox(height: 20),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          Expanded(child: _buildPricingCard(plans[i])),
          if (i < plans.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.greyText),
          SizedBox(height: 16),
          Text(
            'No plans available yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Subscription plans will appear here once they are created and activated in the admin panel.',
            style: TextStyle(fontSize: 14, color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
        ],
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
          style: TextStyle(fontSize: 16, color: AppTheme.greyText),
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

  Widget _buildPricingCard(SubscriptionPlanModel plan) {
    final isLoading = _loadingPlanId == plan.id;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withOpacity(0.2),
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (plan.isPopular)
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
                Text(plan.icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.formattedPrice,
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
                        plan.period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (plan.monthlyGenerationLimit > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            plan.generationLimitLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ...plan.features.map(
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
                            style: const TextStyle(fontSize: 14, color: Colors.white),
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
                    onPressed: isLoading || _loadingPlanId != null
                        ? null
                        : () => _startPaidCheckout(plan),
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
                    label: Text(isLoading ? 'Redirecting…' : plan.buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.isPopular ? AppTheme.primaryGreen : Colors.transparent,
                      foregroundColor:
                          plan.isPopular ? AppTheme.darkBackground : Colors.white,
                      side: plan.isPopular
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
