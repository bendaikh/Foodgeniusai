import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Package identifiers expected under the RevenueCat `default` offering.
class RevenueCatPackageIds {
  RevenueCatPackageIds._();

  static const String basic = 'basic';
  static const String pro = 'pro';
  static const String premium = 'premium';

  /// All valid paid tiers, ordered highest → lowest.
  static const List<String> tiersByPriority = [premium, pro, basic];

  static bool isValidTier(String? tier) =>
      tier != null && tiersByPriority.contains(tier);
}

/// Named packages from the configured subscription offering.
class RevenueCatSubscriptionPackages {
  const RevenueCatSubscriptionPackages({
    this.basic,
    this.pro,
    this.premium,
  });

  final Package? basic;
  final Package? pro;
  final Package? premium;

  bool get hasAny => basic != null || pro != null || premium != null;

  List<Package> get available => [
        if (basic != null) basic!,
        if (pro != null) pro!,
        if (premium != null) premium!,
      ];
}

/// Outcome of a RevenueCat purchase attempt.
enum RevenueCatPurchaseStatus {
  success,
  cancelled,
  failed,
}

class RevenueCatPurchaseOutcome {
  const RevenueCatPurchaseOutcome._({
    required this.status,
    this.customerInfo,
    this.debugDetail,
  });

  final RevenueCatPurchaseStatus status;
  final CustomerInfo? customerInfo;
  final String? debugDetail;

  bool get isSuccess => status == RevenueCatPurchaseStatus.success;
  bool get wasCancelled => status == RevenueCatPurchaseStatus.cancelled;
  bool get isFailure => status == RevenueCatPurchaseStatus.failed;

  factory RevenueCatPurchaseOutcome.success(CustomerInfo info) {
    return RevenueCatPurchaseOutcome._(
      status: RevenueCatPurchaseStatus.success,
      customerInfo: info,
    );
  }

  factory RevenueCatPurchaseOutcome.cancelled() {
    return const RevenueCatPurchaseOutcome._(
      status: RevenueCatPurchaseStatus.cancelled,
    );
  }

  factory RevenueCatPurchaseOutcome.failed(String debugDetail) {
    return RevenueCatPurchaseOutcome._(
      status: RevenueCatPurchaseStatus.failed,
      debugDetail: debugDetail,
    );
  }
}

/// RevenueCat access for offerings, packages, entitlements, purchases, and restore.
///
/// Does not replace Dodo Payments on web. Syncs the same Firestore subscription
/// fields the rest of the app already reads (`subscriptionTier` / `subscriptionStatus`).
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  /// Offering identifier configured in the RevenueCat dashboard.
  static const String defaultOfferingId = 'default';

  /// Entitlement identifier that unlocks paid access in RevenueCat.
  static const String premiumEntitlementId = 'premium';

  /// Fetches all offerings from RevenueCat.
  Future<Offerings?> getOfferings() async {
    if (!await _ensureReady('getOfferings')) return null;

    try {
      final offerings = await Purchases.getOfferings();
      debugPrint(
        'RevenueCatService: fetched ${offerings.all.length} offering(s); '
        'current=${offerings.current?.identifier ?? 'none'}',
      );
      return offerings;
    } catch (e, stackTrace) {
      _logError('getOfferings', e, stackTrace);
      return null;
    }
  }

  /// Fetches the current offering from RevenueCat (dashboard "current").
  Future<Offering?> getCurrentOffering() async {
    final offerings = await getOfferings();
    final current = offerings?.current;
    if (current == null) {
      debugPrint('RevenueCatService: no current offering available');
    } else {
      debugPrint(
        'RevenueCatService: current offering=${current.identifier} '
        '(${current.availablePackages.length} package(s))',
      );
    }
    return current;
  }

  /// Fetches the offering with identifier [defaultOfferingId] (`default`).
  Future<Offering?> getDefaultOffering() async {
    if (!await _ensureReady('getDefaultOffering')) return null;

    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(defaultOfferingId);
      if (offering == null) {
        debugPrint(
          'RevenueCatService: offering "$defaultOfferingId" not found. '
          'Available: ${offerings.all.keys.join(', ')}',
        );
        return null;
      }
      debugPrint(
        'RevenueCatService: offering "$defaultOfferingId" loaded '
        '(${offering.availablePackages.length} package(s))',
      );
      return offering;
    } catch (e, stackTrace) {
      _logError('getDefaultOffering', e, stackTrace);
      return null;
    }
  }

  /// Returns packages `basic`, `pro`, and `premium` from offering `default`.
  ///
  /// Falls back to the current offering if `default` is missing.
  Future<RevenueCatSubscriptionPackages> getSubscriptionPackages({
    Offering? offering,
  }) async {
    final resolved = offering ??
        await getDefaultOffering() ??
        await getCurrentOffering();

    if (resolved == null) {
      debugPrint(
        'RevenueCatService: cannot resolve subscription packages — '
        'no offering available',
      );
      return const RevenueCatSubscriptionPackages();
    }

    final basic = resolved.getPackage(RevenueCatPackageIds.basic);
    final pro = resolved.getPackage(RevenueCatPackageIds.pro);
    final premium = resolved.getPackage(RevenueCatPackageIds.premium);

    debugPrint(
      'RevenueCatService: packages from "${resolved.identifier}" — '
      'basic=${basic != null}, pro=${pro != null}, premium=${premium != null}',
    );
    if (basic == null || pro == null || premium == null) {
      final found =
          resolved.availablePackages.map((p) => p.identifier).join(', ');
      debugPrint(
        'RevenueCatService: expected basic/pro/premium; found: $found',
      );
    }

    return RevenueCatSubscriptionPackages(
      basic: basic,
      pro: pro,
      premium: premium,
    );
  }

  /// Fetches the latest [CustomerInfo] for the current RevenueCat user.
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!await _ensureReady('getCustomerInfo')) return null;

    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint(
        'RevenueCatService: customerInfo active entitlements='
        '${info.entitlements.active.keys.join(', ')}',
      );
      return info;
    } catch (e, stackTrace) {
      _logError('getCustomerInfo', e, stackTrace);
      return null;
    }
  }

  /// Whether entitlement [premiumEntitlementId] (`premium`) is currently active
  /// on the given [info], or on a fresh [getCustomerInfo] fetch when omitted.
  Future<bool> hasPremiumEntitlement([CustomerInfo? info]) async {
    final resolved = info ?? await getCustomerInfo();
    if (resolved == null) return false;

    final active =
        resolved.entitlements.active.containsKey(premiumEntitlementId);
    debugPrint(
      'RevenueCatService: entitlement "$premiumEntitlementId" active=$active',
    );
    return active;
  }

  /// Resolves the subscription tier (`basic` / `pro` / `premium`) from the
  /// verified active products in [info].
  ///
  /// This is the single trusted product→tier mapping used by both the normal
  /// purchase flow and Restore Purchases:
  /// 1. Requires the paid entitlement ([premiumEntitlementId]) to be active.
  /// 2. Collects the active subscription product identifiers plus the product
  ///    backing the active entitlement.
  /// 3. Maps each product to a tier via the `default` offering's
  ///    basic/pro/premium packages (falling back to a product-id heuristic if
  ///    offerings cannot be fetched).
  /// 4. Returns the highest matched tier (premium > pro > basic), or `null`
  ///    when no recognized product is active — callers must NOT unlock or
  ///    default to any tier in that case.
  Future<String?> resolveActiveTier([CustomerInfo? info]) async {
    final resolved = info ?? await getCustomerInfo();
    if (resolved == null) return null;

    final entitlement = resolved.entitlements.active[premiumEntitlementId];
    if (entitlement == null) {
      debugPrint(
        'RevenueCatService: resolveActiveTier — entitlement '
        '"$premiumEntitlementId" not active',
      );
      return null;
    }

    final candidateProductIds = <String>{
      ...resolved.activeSubscriptions,
      if (entitlement.productIdentifier.isNotEmpty)
        entitlement.productIdentifier,
    };
    if (candidateProductIds.isEmpty) {
      debugPrint(
        'RevenueCatService: resolveActiveTier — no active products found',
      );
      return null;
    }

    final productToTier = await _productToTierMap();
    final matchedTiers = <String>{};
    for (final productId in candidateProductIds) {
      final tier =
          productToTier[productId] ?? _tierFromProductIdentifier(productId);
      if (tier != null) matchedTiers.add(tier);
    }

    for (final tier in RevenueCatPackageIds.tiersByPriority) {
      if (matchedTiers.contains(tier)) {
        debugPrint(
          'RevenueCatService: resolveActiveTier — products='
          '${candidateProductIds.join(', ')} → tier="$tier"',
        );
        return tier;
      }
    }

    debugPrint(
      'RevenueCatService: resolveActiveTier — no recognized tier for '
      'products: ${candidateProductIds.join(', ')}',
    );
    return null;
  }

  /// Maps App Store product identifiers → tier using the configured
  /// basic/pro/premium packages of the default offering.
  Future<Map<String, String>> _productToTierMap() async {
    try {
      final packages = await getSubscriptionPackages();
      return {
        if (packages.basic != null)
          packages.basic!.storeProduct.identifier: RevenueCatPackageIds.basic,
        if (packages.pro != null)
          packages.pro!.storeProduct.identifier: RevenueCatPackageIds.pro,
        if (packages.premium != null)
          packages.premium!.storeProduct.identifier:
              RevenueCatPackageIds.premium,
      };
    } catch (e, stackTrace) {
      _logError('_productToTierMap', e, stackTrace);
      return const {};
    }
  }

  /// Fallback when offerings are unavailable: infer the tier from the raw
  /// product identifier. Checked in priority order; returns `null` when the
  /// product does not clearly correspond to a known tier.
  String? _tierFromProductIdentifier(String productIdentifier) {
    final id = productIdentifier.toLowerCase();
    if (id.contains(RevenueCatPackageIds.premium)) {
      return RevenueCatPackageIds.premium;
    }
    if (id.contains(RevenueCatPackageIds.pro)) {
      return RevenueCatPackageIds.pro;
    }
    if (id.contains(RevenueCatPackageIds.basic)) {
      return RevenueCatPackageIds.basic;
    }
    return null;
  }

  /// Purchases the `basic` package from the default offering.
  Future<RevenueCatPurchaseOutcome> purchaseBasic() async {
    return _purchaseNamedPackage(
      RevenueCatPackageIds.basic,
      (packages) => packages.basic,
    );
  }

  /// Purchases the `pro` package from the default offering.
  Future<RevenueCatPurchaseOutcome> purchasePro() async {
    return _purchaseNamedPackage(
      RevenueCatPackageIds.pro,
      (packages) => packages.pro,
    );
  }

  /// Purchases the `premium` package from the default offering.
  Future<RevenueCatPurchaseOutcome> purchasePremium() async {
    return _purchaseNamedPackage(
      RevenueCatPackageIds.premium,
      (packages) => packages.premium,
    );
  }

  /// Purchases the given [package].
  ///
  /// Never throws. Distinguishes success, user cancellation, and failures.
  Future<RevenueCatPurchaseOutcome> purchasePackage(Package package) async {
    if (!await _ensureReady('purchasePackage(${package.identifier})')) {
      return RevenueCatPurchaseOutcome.failed(
        'Purchases SDK is not configured',
      );
    }

    try {
      debugPrint(
        'RevenueCatService: purchasing package="${package.identifier}" '
        'product=${package.storeProduct.identifier}',
      );
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      debugPrint(
        'RevenueCatService: purchase succeeded for '
        '"${package.identifier}"; active entitlements='
        '${result.customerInfo.entitlements.active.keys.join(', ')}',
      );
      return RevenueCatPurchaseOutcome.success(result.customerInfo);
    } on PlatformException catch (e, stackTrace) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint(
          'RevenueCatService: purchase cancelled by user '
          '(package=${package.identifier})',
        );
        return RevenueCatPurchaseOutcome.cancelled();
      }
      _logError(
        'purchasePackage(${package.identifier}) [$code]',
        e,
        stackTrace,
      );
      return RevenueCatPurchaseOutcome.failed(
        'Purchase failed ($code): ${e.message ?? e}',
      );
    } catch (e, stackTrace) {
      _logError('purchasePackage(${package.identifier})', e, stackTrace);
      return RevenueCatPurchaseOutcome.failed('Purchase failed: $e');
    }
  }

  /// Restores previous purchases and returns updated [CustomerInfo].
  ///
  /// Returns `null` if restore fails or Purchases is not configured.
  Future<CustomerInfo?> restorePurchases() async {
    if (!await _ensureReady('restorePurchases')) return null;

    try {
      debugPrint('RevenueCatService: restoring purchases…');
      final info = await Purchases.restorePurchases();
      debugPrint(
        'RevenueCatService: restore succeeded; active entitlements='
        '${info.entitlements.active.keys.join(', ')}',
      );
      return info;
    } catch (e, stackTrace) {
      _logError('restorePurchases', e, stackTrace);
      return null;
    }
  }

  /// Syncs the active paid tier to the user's Firestore profile through the
  /// trusted `syncRevenueCatSubscription` Cloud Function so
  /// [AuthService.hasPaidSubscription] reflects an active paid plan.
  ///
  /// Clients can no longer write `subscriptionTier` / `subscriptionStatus`
  /// directly (blocked by Firestore rules); the backend performs the write.
  ///
  /// [tier] must be one of `basic`, `pro`, `premium`, already derived via
  /// [resolveActiveTier]. [customerInfo] supplies the active product IDs the
  /// backend uses to re-verify the mapping.
  Future<bool> syncPaidSubscriptionToProfile({
    required String tier,
    CustomerInfo? customerInfo,
    String? purchasedPackageId,
  }) async {
    if (!RevenueCatPackageIds.isValidTier(tier)) {
      debugPrint(
        'RevenueCatService: refusing to sync unrecognized tier "$tier"',
      );
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        debugPrint(
          'RevenueCatService: cannot sync subscription — user not signed in',
        );
        return false;
      }

      // RevenueCat app user id lets the backend verify the subscription
      // against the RevenueCat REST API when a secret key is configured.
      String? appUserId;
      try {
        if (await Purchases.isConfigured) {
          appUserId = await Purchases.appUserID;
        }
      } catch (_) {
        appUserId = null;
      }

      final productIds = <String>{
        if (customerInfo != null) ...customerInfo.activeSubscriptions,
      };
      final entitlement = customerInfo
          ?.entitlements.active[premiumEntitlementId];
      final entitlementProduct = entitlement?.productIdentifier;
      if (entitlementProduct != null && entitlementProduct.isNotEmpty) {
        productIds.add(entitlementProduct);
      }
      // Package ids (`basic` / `pro` / `premium`) also map on the backend —
      // include the just-purchased package so a momentary empty product list
      // cannot block a legitimate purchase sync. Restore must NOT use this.
      if (RevenueCatPackageIds.isValidTier(purchasedPackageId)) {
        productIds.add(purchasedPackageId!);
      }

      // Latest purchase date anchors the billing-period quota window server-side.
      int? billingPeriodStartMs;
      final latestPurchase = entitlement?.latestPurchaseDate;
      if (latestPurchase != null && latestPurchase.isNotEmpty) {
        billingPeriodStartMs = DateTime.tryParse(latestPurchase)
            ?.millisecondsSinceEpoch;
      }

      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('syncRevenueCatSubscription')
          .call<dynamic>({
        'tier': tier,
        if (appUserId != null) 'appUserId': appUserId,
        'productIds': productIds.toList(),
        if (billingPeriodStartMs != null)
          'billingPeriodStartMs': billingPeriodStartMs,
      });

      final data = result.data;
      final success = data is Map && data['success'] == true;
      final syncedTier = data is Map ? data['tier'] : null;
      debugPrint(
        'RevenueCatService: backend sync requested="$tier" '
        'synced="$syncedTier" success=$success for ${user.uid}',
      );
      return success;
    } catch (e, stackTrace) {
      _logError('syncPaidSubscriptionToProfile', e, stackTrace);
      return false;
    }
  }

  Future<RevenueCatPurchaseOutcome> _purchaseNamedPackage(
    String packageId,
    Package? Function(RevenueCatSubscriptionPackages packages) pick,
  ) async {
    if (!await _ensureReady('purchase$packageId')) {
      return RevenueCatPurchaseOutcome.failed(
        'Purchases SDK is not configured',
      );
    }

    try {
      final packages = await getSubscriptionPackages();
      final package = pick(packages);
      if (package == null) {
        debugPrint(
          'RevenueCatService: cannot purchase "$packageId" — package not found',
        );
        return RevenueCatPurchaseOutcome.failed(
          'Package "$packageId" was not found in the current offering',
        );
      }
      return purchasePackage(package);
    } catch (e, stackTrace) {
      _logError('purchase$packageId', e, stackTrace);
      return RevenueCatPurchaseOutcome.failed('Purchase failed: $e');
    }
  }

  Future<bool> _ensureReady(String operation) async {
    try {
      final configured = await Purchases.isConfigured;
      if (!configured) {
        debugPrint(
          'RevenueCatService: skipping $operation — Purchases not configured '
          '(expected on non-iOS or before init)',
        );
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      _logError('_ensureReady($operation)', e, stackTrace);
      return false;
    }
  }

  void _logError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('RevenueCatService: $operation failed: $error');
    debugPrint('$stackTrace');
  }
}
