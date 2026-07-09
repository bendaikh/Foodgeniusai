import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks recipe generation usage on the user profile (idempotent per recipe).
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

    await _firestore.collection('users').doc(userId).set({
      'monthlyGenerationsUsed': FieldValue.increment(1),
      'totalRecipesGenerated': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await recipeRef.set(
      {'generationCounted': true},
      SetOptions(merge: true),
    );

    return true;
  }
}
