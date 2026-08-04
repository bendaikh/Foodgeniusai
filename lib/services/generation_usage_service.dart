import 'package:cloud_firestore/cloud_firestore.dart';

/// Marks a recipe as having been counted once.
///
/// Paid monthly quotas are owned exclusively by Cloud Functions
/// (`consumeRecipeGeneration`). This helper must not mutate
/// `monthlyGenerationsUsed`.
class GenerationUsageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> recordIfNeeded({
    required String userId,
    required String recipeId,
  }) async {
    if (recipeId.isEmpty) return false;

    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnap = await recipeRef.get();
    if (recipeSnap.data()?['generationCounted'] == true) {
      return false;
    }

    await recipeRef.set(
      {'generationCounted': true},
      SetOptions(merge: true),
    );

    return true;
  }
}
