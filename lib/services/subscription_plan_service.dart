import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_plan_model.dart';
import 'dodopayment_service.dart';

class SubscriptionPlanService {
  static final SubscriptionPlanService _instance =
      SubscriptionPlanService._internal();
  factory SubscriptionPlanService() => _instance;
  SubscriptionPlanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'subscription_plans';

  Stream<List<SubscriptionPlanModel>> watchAllPlans() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final plans = snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromFirestore(doc))
          .toList();
      plans.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000));
      });
      return plans;
    });
  }

  Stream<List<SubscriptionPlanModel>> watchActivePlans() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final plans = snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromFirestore(doc))
          .toList();
      plans.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return (a.createdAt ?? DateTime(2000))
            .compareTo(b.createdAt ?? DateTime(2000));
      });
      return plans;
    });
  }

  Future<SubscriptionPlanModel> createPlan({
    required String name,
    required String description,
    required double price,
    required String currency,
    required List<String> features,
    String icon = '💎',
    String buttonText = 'Subscribe',
    String period = '/ month',
    bool isPopular = false,
    bool isActive = true,
    int? sortOrder,
    int monthlyGenerationLimit = 0,
  }) async {
    await DodoPaymentService().loadConfiguration();
    if (!DodoPaymentService().isConfigured) {
      throw Exception('DodoPayment is not configured. Go to Settings first.');
    }

    final dodoProduct = await DodoPaymentService().createProduct(
      name: name,
      description: description,
      priceInDollars: price,
      currency: currency,
    );

    final productId = dodoProduct['product_id'] as String? ??
        dodoProduct['id'] as String? ??
        '';

    if (productId.isEmpty) {
      throw Exception('DodoPayments did not return a product ID.');
    }

    final existingDocs = await _firestore.collection(_collection).get();
    final nextSortOrder = sortOrder ?? existingDocs.docs.length;

    final docRef = _firestore.collection(_collection).doc();
    final plan = SubscriptionPlanModel(
      id: docRef.id,
      name: name,
      description: description,
      price: price,
      currency: currency.toUpperCase(),
      dodoProductId: productId,
      features: features,
      icon: icon,
      buttonText: buttonText,
      period: period,
      isActive: isActive,
      isPopular: isPopular,
      sortOrder: nextSortOrder,
      monthlyGenerationLimit: monthlyGenerationLimit,
    );

    await docRef.set(plan.toMap());
    return plan;
  }

  Future<void> updatePlan(SubscriptionPlanModel plan) async {
    await _firestore.collection(_collection).doc(plan.id).set(
          plan.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> setPlanActive(String planId, bool isActive) async {
    await _firestore.collection(_collection).doc(planId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    await _firestore.collection(_collection).doc(planId).delete();
  }

  Future<SubscriptionPlanModel?> getPlanById(String planId) async {
    final doc = await _firestore.collection(_collection).doc(planId).get();
    if (!doc.exists) return null;
    return SubscriptionPlanModel.fromFirestore(doc);
  }
}
