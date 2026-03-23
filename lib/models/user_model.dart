import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String subscriptionTier;
  final String subscriptionStatus;
  final DateTime? createdAt;
  final int totalRecipesGenerated;
  final int apiUsageCount;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    required this.subscriptionTier,
    required this.subscriptionStatus,
    this.createdAt,
    this.totalRecipesGenerated = 0,
    this.apiUsageCount = 0,
    this.role = 'user',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      subscriptionTier: data['subscriptionTier'] ?? 'free',
      subscriptionStatus: data['subscriptionStatus'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      totalRecipesGenerated: data['totalRecipesGenerated'] ?? 0,
      apiUsageCount: data['apiUsageCount'] ?? 0,
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'subscriptionTier': subscriptionTier,
      'subscriptionStatus': subscriptionStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'totalRecipesGenerated': totalRecipesGenerated,
      'apiUsageCount': apiUsageCount,
      'role': role,
    };
  }
}
