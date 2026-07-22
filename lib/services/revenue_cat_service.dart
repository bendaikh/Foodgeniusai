import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Writes the existing Firestore subscription fields so
  /// [AuthService.hasPaidSubscription] reflects an active paid plan.
  ///
  /// [tier] should be a non-`free` identifier (e.g. `basic`, `pro`, `premium`).
  Future<bool> syncPaidSubscriptionToProfile({required String tier}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        debugPrint(
          'RevenueCatService: cannot sync subscription — user not signed in',
        );
        return false;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'subscriptionTier': tier,
          'subscriptionStatus': 'active',
          'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
          'subscriptionSource': 'revenue_cat',
        },
        SetOptions(merge: true),
      );
      debugPrint(
        'RevenueCatService: synced subscriptionTier="$tier" for ${user.uid}',
      );
      return true;
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
