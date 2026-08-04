import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show CustomerInfo, Package;

import '../models/recipe_model.dart';
import '../models/subscription_plan_model.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/recipe_generation_service.dart';
import '../services/revenue_cat_paywall_marketing.dart';
import '../services/revenue_cat_service.dart';
import '../services/subscription_plan_service.dart';
import '../theme/app_theme.dart';
import '../utils/checkout_redirect.dart';
import 'user_auth_page.dart';

/// Shared display model for paywall cards (same visual design for all platforms).
class _PaywallCardData {
  const _PaywallCardData({
    required this.id,
    required this.name,
    required this.description,
    required this.formattedPrice,
    required this.period,
    required this.features,
    required this.icon,
    required this.buttonText,
    required this.isPopular,
    required this.limitBadges,
    this.firestorePlan,
    this.revenueCatPackage,
  });

  final String id;
  final String name;
  final String description;
  final String formattedPrice;
  final String period;
  final List<String> features;
  final String icon;
  final String buttonText;
  final bool isPopular;

  /// Highlight chips under the price (recipe + fridge limits on iOS).
  final List<String> limitBadges;

  /// Web / non-iOS Dodo checkout source.
  final SubscriptionPlanModel? firestorePlan;

  /// iOS RevenueCat package to purchase directly.
  final Package? revenueCatPackage;

  factory _PaywallCardData.fromFirestore(SubscriptionPlanModel plan) {
    final badges = <String>[];
    if (plan.monthlyGenerationLimit > 0) {
      badges.add(plan.generationLimitLabel);
    }
    return _PaywallCardData(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      formattedPrice: plan.formattedPrice,
      period: plan.period,
      features: plan.features,
      icon: plan.icon,
      buttonText: plan.buttonText,
      isPopular: plan.isPopular,
      limitBadges: badges,
      firestorePlan: plan,
    );
  }

  factory _PaywallCardData.fromRevenueCatPackage(Package package) {
    final product = package.storeProduct;
    final marketing =
        RevenueCatPaywallMarketing.forPackageId(package.identifier);
    // Prefer App Store product title; fall back to marketing label.
    final name = product.title.trim().isNotEmpty
        ? product.title.trim()
        : marketing.displayName;
    final description = product.description.trim().isNotEmpty
        ? product.description.trim()
        : marketing.description;

    return _PaywallCardData(
      id: package.identifier,
      name: name,
      description: description,
      formattedPrice: product.priceString,
      period: RevenueCatPaywallMarketing.periodLabelFor(
        product,
        package.packageType,
      ),
      features: marketing.features,
      icon: marketing.icon,
      buttonText: marketing.buttonText,
      isPopular: marketing.isPopular,
      limitBadges: [
        marketing.recipeLimitLabel,
        marketing.fridgeScanLimitLabel,
      ],
      revenueCatPackage: package,
    );
  }
}

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

  /// iOS-only offerings load state (never falls back to Firestore prices).
  bool _iosOfferingsLoading = false;
  String? _iosOfferingsError;
  List<_PaywallCardData> _iosCards = const [];

  /// App Store purchases via RevenueCat — iOS only. Web keeps Dodo; Android unchanged.
  bool get _useRevenueCatOnIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecipeOnOpen());
    if (_useRevenueCatOnIos) {
      _loadIosRevenueCatOfferings();
    }
  }

  Future<void> _syncRecipeOnOpen() async {
    if (widget.returnRecipe != null) {
      await _recipeGenerationService.ensureInMyRecipes(widget.returnRecipe!);
      return;
    }
    await _recipeGenerationService.syncPendingToMyRecipes();
  }

  Future<void> _loadIosRevenueCatOfferings() async {
    if (!_useRevenueCatOnIos) return;

    setState(() {
      _iosOfferingsLoading = true;
      _iosOfferingsError = null;
    });

    try {
      final packages = await _revenueCat.getSubscriptionPackages();
      if (!mounted) return;

      final cards = <_PaywallCardData>[
        if (packages.basic != null)
          _PaywallCardData.fromRevenueCatPackage(packages.basic!),
        if (packages.pro != null)
          _PaywallCardData.fromRevenueCatPackage(packages.pro!),
        if (packages.premium != null)
          _PaywallCardData.fromRevenueCatPackage(packages.premium!),
      ];

      if (cards.isEmpty) {
        setState(() {
          _iosOfferingsLoading = false;
          _iosCards = const [];
          _iosOfferingsError =
              'Subscription products are unavailable right now. Please try again.';
        });
        return;
      }

      setState(() {
        _iosOfferingsLoading = false;
        _iosCards = cards;
        _iosOfferingsError = null;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PricingPage: failed to load RC offerings: $e');
        debugPrint('$stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _iosOfferingsLoading = false;
        _iosCards = const [];
        _iosOfferingsError =
            'Could not load App Store plans. Please check your connection and try again.';
      });
    }
  }

  Future<bool> _ensureSignedIn() async {
    if (_authService.isAuthenticatedUser) return true;
    if (!mounted) return false;

    // Push auth on top of pricing. The selected plan stays alive in the
    // caller's local variables; on success we pop back here and continue
    // purchasing that same package. On cancel/failure, return false and
    // do not start a purchase.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => const UserAuthPage(isLogin: false),
      ),
    );
    if (!mounted) return false;
    return _authService.isAuthenticatedUser;
  }

  Future<void> _preparePendingRecipe() async {
    if (widget.returnRecipe != null) {
      await _recipeGenerationService.ensureInMyRecipes(widget.returnRecipe!);
    } else {
      await _recipeGenerationService.syncPendingToMyRecipes();
    }
  }

  Future<void> _onSubscribePressed(_PaywallCardData card) async {
    if (_useRevenueCatOnIos) {
      await _startRevenueCatPurchase(card);
      return;
    }

    final plan = card.firestorePlan;
    if (plan == null) return;
    await _startDodoCheckout(plan);
  }

  /// Web / Android: existing Firestore plan → Dodo checkout (unchanged).
  Future<void> _startDodoCheckout(SubscriptionPlanModel plan) async {
    if (!await _ensureSignedIn()) return;
    await _preparePendingRecipe();

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

  /// iOS: purchase the exact RevenueCat [Package] on the card.
  Future<void> _startRevenueCatPurchase(_PaywallCardData card) async {
    final package = card.revenueCatPackage;
    if (package == null) {
      setState(() {
        _errorMessage = 'This plan is not available for App Store purchase yet.';
      });
      return;
    }

    if (!await _ensureSignedIn()) return;
    await _preparePendingRecipe();

    setState(() {
      _loadingPlanId = card.id;
      _errorMessage = null;
    });

    final outcome = await _revenueCat.purchasePackage(package);

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
      purchasedPackageId: package.identifier,
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

    // Tier is derived inside _finishRevenueCatUnlock from the actual active
    // RevenueCat products — never assume a tier when restoring.
    await _finishRevenueCatUnlock(
      customerInfo: info,
      restoring: true,
    );
  }

  Future<void> _finishRevenueCatUnlock({
    CustomerInfo? customerInfo,
    String? purchasedPackageId,
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

    // Derive the tier from the verified active products (premium > pro >
    // basic). For a fresh purchase, fall back to the exact package that was
    // just bought if product mapping is momentarily unavailable.
    var tier = await _revenueCat.resolveActiveTier(refreshed);
    if (tier == null &&
        !restoring &&
        RevenueCatPackageIds.isValidTier(purchasedPackageId)) {
      tier = purchasedPackageId;
    }

    if (!mounted) return;

    if (tier == null) {
      // Entitled but no recognized product: do not write any tier or unlock.
      setState(() {
        _loadingPlanId = null;
        _isRestoring = false;
        _errorMessage = restoring
            ? 'No active subscription found to restore.'
            : 'We could not verify your subscription plan. Please try Restore Purchases or contact support.';
      });
      return;
    }

    final synced = await _revenueCat.syncPaidSubscriptionToProfile(
      tier: tier,
      customerInfo: refreshed,
      // Only pass for a fresh purchase — restore must rely on active products.
      purchasedPackageId: restoring ? null : purchasedPackageId,
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
        child: _useRevenueCatOnIos
            ? _buildIosBody(isMobile: isMobile)
            : _buildFirestoreBody(isMobile: isMobile),
      ),
    );
  }

  Widget _buildIosBody({required bool isMobile}) {
    if (_iosOfferingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_iosOfferingsError != null && _iosCards.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 40),
              _buildIosOfferingsErrorState(),
            ],
          ),
        ),
      );
    }

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
            if (_iosCards.isEmpty)
              _buildIosOfferingsErrorState()
            else
              _buildPlansGrid(_iosCards, isMobile),
            const SizedBox(height: 24),
            _buildRestorePurchasesButton(),
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
  }

  Widget _buildFirestoreBody({required bool isMobile}) {
    return StreamBuilder<List<SubscriptionPlanModel>>(
      stream: _planService.watchActivePlans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final plans = snapshot.data ?? [];
        final cards =
            plans.map(_PaywallCardData.fromFirestore).toList(growable: false);

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
                if (cards.isEmpty)
                  _buildEmptyState()
                else
                  _buildPlansGrid(cards, isMobile),
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
    );
  }

  Widget _buildIosOfferingsErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 48, color: AppTheme.greyText),
          const SizedBox(height: 16),
          const Text(
            'Plans unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _iosOfferingsError ??
                'Subscription products are unavailable right now. Please try again.',
            style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _iosOfferingsLoading ? null : _loadIosRevenueCatOfferings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.darkBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansGrid(List<_PaywallCardData> plans, bool isMobile) {
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
    final subtitle = _useRevenueCatOnIos
        ? 'Pick a plan and subscribe securely through the App Store. After purchase, your recipe unlocks automatically.'
        : 'Pick a plan and pay securely with DodoPayment. After payment, you\'ll return to your generated recipe fully unlocked.';

    return Column(
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: AppTheme.greyText),
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

  Widget _buildPricingCard(_PaywallCardData plan) {
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
                    if (plan.period.isNotEmpty) ...[
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
                  ],
                ),
                if (plan.limitBadges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...plan.limitBadges.map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                                badge,
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
                        : () => _onSubscribePressed(plan),
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
