import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenue_cat_service.dart';

/// Marketing copy for iOS paywall cards, keyed by RevenueCat package id.
///
/// Prices and billing periods always come from [StoreProduct] — never from here.
/// Limits here must match server enforcement in Cloud Functions.
class RevenueCatPaywallMarketing {
  const RevenueCatPaywallMarketing({
    required this.displayName,
    required this.description,
    required this.features,
    required this.icon,
    required this.buttonText,
    required this.isPopular,
    required this.recipeGenerationsPerMonth,
    required this.fridgeScansPerMonth,
  });

  final String displayName;
  final String description;
  final List<String> features;
  final String icon;
  final String buttonText;
  final bool isPopular;

  /// Null means unlimited recipe generations.
  final int? recipeGenerationsPerMonth;

  /// Null means unlimited Fridge Scans.
  final int? fridgeScansPerMonth;

  String get recipeLimitLabel {
    if (recipeGenerationsPerMonth == null) {
      return 'Unlimited Recipe Generations';
    }
    final n = recipeGenerationsPerMonth!;
    return '$n Recipe Generation${n == 1 ? '' : 's'} / month';
  }

  String get fridgeScanLimitLabel {
    if (fridgeScansPerMonth == null) {
      return 'Unlimited Fridge Scans';
    }
    final n = fridgeScansPerMonth!;
    return '$n Fridge Scan${n == 1 ? '' : 's'} / month';
  }

  static const RevenueCatPaywallMarketing basic = RevenueCatPaywallMarketing(
    displayName: 'Basic',
    description: 'Start cooking smarter with essential AI recipes.',
    features: [
      '20 Recipe Generations / month',
      '5 Fridge Scans / month',
      'Save your favorite recipes',
      'Ingredient-based suggestions',
    ],
    icon: '🥗',
    buttonText: 'Subscribe',
    isPopular: false,
    recipeGenerationsPerMonth: 20,
    fridgeScansPerMonth: 5,
  );

  static const RevenueCatPaywallMarketing pro = RevenueCatPaywallMarketing(
    displayName: 'Pro',
    description: 'More recipes and tools for everyday cooking.',
    features: [
      'Unlimited Recipe Generations',
      '20 Fridge Scans / month',
      'Scan ingredients for recipes',
      'Save unlimited favorites',
    ],
    icon: '👨‍🍳',
    buttonText: 'Subscribe',
    isPopular: true,
    recipeGenerationsPerMonth: null,
    fridgeScansPerMonth: 20,
  );

  static const RevenueCatPaywallMarketing premium = RevenueCatPaywallMarketing(
    displayName: 'Premium',
    description: 'Maximum creativity for serious home chefs.',
    features: [
      'Unlimited Recipe Generations',
      'Unlimited Fridge Scans',
      'All Pro features included',
      'Early access to new features',
    ],
    icon: '💎',
    buttonText: 'Subscribe',
    isPopular: false,
    recipeGenerationsPerMonth: null,
    fridgeScansPerMonth: null,
  );

  static RevenueCatPaywallMarketing forPackageId(String packageId) {
    switch (packageId) {
      case RevenueCatPackageIds.basic:
        return basic;
      case RevenueCatPackageIds.pro:
        return pro;
      case RevenueCatPackageIds.premium:
        return premium;
      default:
        return const RevenueCatPaywallMarketing(
          displayName: 'Plan',
          description: '',
          features: [],
          icon: '💎',
          buttonText: 'Subscribe',
          isPopular: false,
          recipeGenerationsPerMonth: 0,
          fridgeScansPerMonth: 0,
        );
    }
  }

  /// Human-readable period label from App Store / RevenueCat product data.
  static String periodLabelFor(StoreProduct product, PackageType packageType) {
    final fromIso = _periodFromIso8601(product.subscriptionPeriod);
    if (fromIso != null) return fromIso;

    switch (packageType) {
      case PackageType.weekly:
        return '/ week';
      case PackageType.monthly:
        return '/ month';
      case PackageType.twoMonth:
        return '/ 2 months';
      case PackageType.threeMonth:
        return '/ 3 months';
      case PackageType.sixMonth:
        return '/ 6 months';
      case PackageType.annual:
        return '/ year';
      case PackageType.lifetime:
        return 'lifetime';
      case PackageType.unknown:
      case PackageType.custom:
        return '';
    }
  }

  static String? _periodFromIso8601(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final match = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$')
        .firstMatch(iso.toUpperCase());
    if (match == null) return null;

    final years = int.tryParse(match.group(1) ?? '') ?? 0;
    final months = int.tryParse(match.group(2) ?? '') ?? 0;
    final weeks = int.tryParse(match.group(3) ?? '') ?? 0;
    final days = int.tryParse(match.group(4) ?? '') ?? 0;

    if (years == 1 && months == 0 && weeks == 0 && days == 0) return '/ year';
    if (years > 1 && months == 0 && weeks == 0 && days == 0) {
      return '/ $years years';
    }
    if (months == 1 && years == 0 && weeks == 0 && days == 0) return '/ month';
    if (months > 1 && years == 0 && weeks == 0 && days == 0) {
      return '/ $months months';
    }
    if (weeks == 1 && years == 0 && months == 0 && days == 0) return '/ week';
    if (weeks > 1 && years == 0 && months == 0 && days == 0) {
      return '/ $weeks weeks';
    }
    if (days == 1 && years == 0 && months == 0 && weeks == 0) return '/ day';
    if (days > 1 && years == 0 && months == 0 && weeks == 0) {
      return '/ $days days';
    }
    return null;
  }
}
