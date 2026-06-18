import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String dodoProductId;
  final List<String> features;
  final String icon;
  final String buttonText;
  final String period;
  final bool isActive;
  final bool isPopular;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.dodoProductId,
    this.features = const [],
    this.icon = '💎',
    this.buttonText = 'Subscribe',
    this.period = '/ month',
    this.isActive = true,
    this.isPopular = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  int get priceCents => (price * 100).round();

  String get formattedPrice {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : '${currency.toUpperCase()} ';
    return '$symbol${price == price.roundToDouble() ? price.toInt() : price.toStringAsFixed(2)}';
  }

  factory SubscriptionPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlanModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      dodoProductId: data['dodoProductId'] as String? ?? '',
      features: List<String>.from(data['features'] ?? const []),
      icon: data['icon'] as String? ?? '💎',
      buttonText: data['buttonText'] as String? ?? 'Subscribe',
      period: data['period'] as String? ?? '/ month',
      isActive: data['isActive'] as bool? ?? true,
      isPopular: data['isPopular'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'dodoProductId': dodoProductId,
      'features': features,
      'icon': icon,
      'buttonText': buttonText,
      'period': period,
      'isActive': isActive,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  SubscriptionPlanModel copyWith({
    String? name,
    String? description,
    double? price,
    String? currency,
    String? dodoProductId,
    List<String>? features,
    String? icon,
    String? buttonText,
    String? period,
    bool? isActive,
    bool? isPopular,
    int? sortOrder,
  }) {
    return SubscriptionPlanModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      dodoProductId: dodoProductId ?? this.dodoProductId,
      features: features ?? this.features,
      icon: icon ?? this.icon,
      buttonText: buttonText ?? this.buttonText,
      period: period ?? this.period,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
