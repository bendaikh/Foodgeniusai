import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> instructions;
  final Map<String, dynamic> nutrition;
  final String difficulty;
  final int prepTime;
  final int cookTime;
  final int totalTime;
  final int servings;
  final String cuisine;
  final String mealType;
  final List<String> dietary;
  final String? imageUrl;
  final DateTime? createdAt;
  final int views;
  final int saves;
  final bool isPublic;

  RecipeModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.cuisine,
    required this.mealType,
    this.dietary = const [],
    this.imageUrl,
    this.createdAt,
    this.views = 0,
    this.saves = 0,
    this.isPublic = true,
  });

  factory RecipeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RecipeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      ingredients: List<Map<String, dynamic>>.from(data['ingredients'] ?? []),
      instructions: List<Map<String, dynamic>>.from(data['instructions'] ?? []),
      nutrition: Map<String, dynamic>.from(data['nutrition'] ?? {}),
      difficulty: data['difficulty'] ?? 'intermediate',
      prepTime: data['prepTime'] ?? 0,
      cookTime: data['cookTime'] ?? 0,
      totalTime: data['totalTime'] ?? 0,
      servings: data['servings'] ?? 2,
      cuisine: data['cuisine'] ?? '',
      mealType: data['mealType'] ?? '',
      dietary: List<String>.from(data['dietary'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      views: data['views'] ?? 0,
      saves: data['saves'] ?? 0,
      isPublic: data['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition': nutrition,
      'difficulty': difficulty,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'servings': servings,
      'cuisine': cuisine,
      'mealType': mealType,
      'dietary': dietary,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'views': views,
      'saves': saves,
      'isPublic': isPublic,
    };
  }

  /// JSON for session storage (payment redirect flow).
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition': nutrition,
      'difficulty': difficulty,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'servings': servings,
      'cuisine': cuisine,
      'mealType': mealType,
      'dietary': dietary,
      'imageUrl': imageUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'views': views,
      'saves': saves,
      'isPublic': isPublic,
    };
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? 'guest',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ingredients: List<Map<String, dynamic>>.from(json['ingredients'] ?? []),
      instructions: List<Map<String, dynamic>>.from(json['instructions'] ?? []),
      nutrition: Map<String, dynamic>.from(json['nutrition'] ?? {}),
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      prepTime: (json['prepTime'] as num?)?.toInt() ?? 0,
      cookTime: (json['cookTime'] as num?)?.toInt() ?? 0,
      totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      cuisine: json['cuisine'] as String? ?? '',
      mealType: json['mealType'] as String? ?? '',
      dietary: List<String>.from(json['dietary'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      views: (json['views'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }
}
