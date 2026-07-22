import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show CustomerInfo;

import '../models/recipe_model.dart';
import '../models/subscription_plan_model.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/recipe_generation_service.dart';
import '../services/revenue_cat_service.dart';
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
  final RecipeGenerationService _recipeGenerationService =
      RecipeGenerationService();
  final RevenueCatService _revenueCat = RevenueCatService.instance;

  String? _loadingPlanId;
  String? _errorMessage;
  bool _isRestoring = false;

  /// App Store purchases via RevenueCat — iOS only. Web keeps Dodo; Android unchanged.
  bool get _useRevenueCatOnIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecipeOnOpen());
  }

  Future<void> _syncRecipeOnOpen() async {
    if (widget.returnRecipe != null) {
      await _recipeGenerationService.ensureInMyRecipes(widget.returnRecipe!);
      return;
    }
    await _recipeGenerationService.syncPendingToMyRecipes();
  }

  Future<bool> _ensureSignedIn() async {
    if (_authService.isAuthenticatedUser) return true;
    if (!mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserAuthPage(isLogin: false),
      ),
    );
    return _authService.isAuthenticatedUser;
  }

  Future<void> _preparePendingRecipe() async {
    if (widget.returnRecipe != null) {
      await _recipeGenerationService.ensureInMyRecipes(widget.returnRecipe!);
    } else {
      await _recipeGenerationService.syncPendingToMyRecipes();
    }
  }

  /// Maps a Firestore plan card to RevenueCat package ids: basic / pro / premium.
  String? _revenueCatPackageIdForPlan(
    SubscriptionPlanModel plan,
    List<SubscriptionPlanModel> allPlans,
  ) {
    final normalized = plan.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.contains('basic')) return RevenueCatPackageIds.basic;
    if (normalized.contains('premium') || normalized.contains('elite')) {
      return RevenueCatPackageIds.premium;
    }
    if (normalized.contains('pro')) return RevenueCatPackageIds.pro;

    final sorted = [...allPlans]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = sorted.indexWhere((p) => p.id == plan.id);
    if (index == 0) return RevenueCatPackageIds.basic;
    if (index == 1) return RevenueCatPackageIds.pro;
    if (index == 2) return RevenueCatPackageIds.premium;
    return null;
  }

  Future<RevenueCatPurchaseOutcome> _purchaseRevenueCatPackage(
    String packageId,
  ) {
    switch (packageId) {
      case RevenueCatPackageIds.basic:
        return _revenueCat.purchaseBasic();
      case RevenueCatPackageIds.pro:
        return _revenueCat.purchasePro();
      case RevenueCatPackageIds.premium:
        return _revenueCat.purchasePremium();
      default:
        return Future.value(
          RevenueCatPurchaseOutcome.failed('Unknown package: $packageId'),
        );
    }
  }

  Future<void> _startPaidCheckout(
    SubscriptionPlanModel plan, {
    required List<SubscriptionPlanModel> allPlans,
  }) async {
    if (!await _ensureSignedIn()) return;
    await _preparePendingRecipe();

    if (_useRevenueCatOnIos) {
      await _startRevenueCatPurchase(plan, allPlans: allPlans);
      return;
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

  Future<void> _startRevenueCatPurchase(
    SubscriptionPlanModel plan, {
    required List<SubscriptionPlanModel> allPlans,
  }) async {
    final packageId = _revenueCatPackageIdForPlan(plan, allPlans);
    if (packageId == null) {
      setState(() {
        _errorMessage = 'This plan is not available for App Store purchase yet.';
      });
      return;
    }

    setState(() {
      _loadingPlanId = plan.id;
      _errorMessage = null;
    });

    final outcome = await _purchaseRevenueCatPackage(packageId);

    if (!mounted) return;

    if (outcome.wasCancelled) {
      setState(() => _loadingPlanId = null);
      return;
    }

    if (outcome.isFailure) {
      if (kDebugMode && outcome.debugDetail != null) {
        debugPrint('PricingPage RC purchase error: ${outcome.debugDetail}');
      }
      setState(() {
        _loadingPlanId = null;
        _errorMessage = 'Purchase could not be completed. Please try again.';
      });
      return;
    }

    await _finishRevenueCatUnlock(
      preferredTier: packageId,
      customerInfo: outcome.customerInfo,
    );
  }

  Future<void> _restorePurchases() async {
    if (!_useRevenueCatOnIos || _isRestoring || _loadingPlanId != null) return;

    if (!await _ensureSignedIn()) return;
    await _preparePendingRecipe();

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    final info = await _revenueCat.restorePurchases();
    if (!mounted) return;

    if (info == null) {
      if (kDebugMode) {
        debugPrint('PricingPage RC restore failed or SDK not configured');
      }
      setState(() {
        _isRestoring = false;
        _errorMessage = 'Could not restore purchases. Please try again.';
      });
      return;
    }

    await _finishRevenueCatUnlock(
      preferredTier: RevenueCatPackageIds.premium,
      customerInfo: info,
      restoring: true,
    );
  }

  Future<void> _finishRevenueCatUnlock({
    required String preferredTier,
    CustomerInfo? customerInfo,
    bool restoring = false,
  }) async {
    // Refresh CustomerInfo, then require entitlement `premium` before closing.
    final refreshed = await _revenueCat.getCustomerInfo() ?? customerInfo;
    final entitled = await _revenueCat.hasPremiumEntitlement(refreshed);

    if (!mounted) return;

    if (!entitled) {
      setState(() {
        _loadingPlanId = null;
        _isRestoring = false;
        _errorMessage = restoring
            ? 'No active subscription found to restore.'
            : 'Purchase finished, but your subscription is not active yet. Try Restore Purchases.';
      });
      return;
    }

    final synced = await _revenueCat.syncPaidSubscriptionToProfile(
      tier: preferredTier,
    );
    if (!mounted) return;

    if (!synced) {
      if (kDebugMode) {
        debugPrint('PricingPage: entitlement active but Firestore sync failed');
      }
      setState(() {
        _loadingPlanId = null;
        _isRestoring = false;
        _errorMessage =
            'Subscription verified, but we could not update your account. Please try again.';
      });
      return;
    }

    setState(() {
      _loadingPlanId = null;
      _isRestoring = false;
      _errorMessage = null;
    });

    if (!mounted) return;
    Navigator.pop(context, true);
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
                    if (_useRevenueCatOnIos) ...[
                      const SizedBox(height: 24),
                      _buildRestorePurchasesButton(),
                    ],
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
            _buildPricingCard(plans[i], allPlans: plans),
            if (i < plans.length - 1) const SizedBox(height: 20),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          Expanded(child: _buildPricingCard(plans[i], allPlans: plans)),
          if (i < plans.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _buildRestorePurchasesButton() {
    return TextButton(
      onPressed:
          _isRestoring || _loadingPlanId != null ? null : _restorePurchases,
      child: _isRestoring
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Restore Purchases',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  Widget _buildPricingCard(
    SubscriptionPlanModel plan, {
    required List<SubscriptionPlanModel> allPlans,
  }) {
    final isLoading = _loadingPlanId == plan.id;
    final busyLabel = _useRevenueCatOnIos ? 'Purchasing…' : 'Redirecting…';

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
                    onPressed: isLoading ||
                            _loadingPlanId != null ||
                            _isRestoring
                        ? null
                        : () =>
                            _startPaidCheckout(plan, allPlans: allPlans),
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
                    label: Text(isLoading ? busyLabel : plan.buttonText),
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
