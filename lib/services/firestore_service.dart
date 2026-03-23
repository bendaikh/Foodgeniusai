import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USERS ============

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // ============ RECIPES ============

  // Get all recipes
  Stream<List<RecipeModel>> getAllRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromFirestore(doc))
            .toList());
  }

  // Get recipes by user
  Stream<List<RecipeModel>> getRecipesByUser(String userId) {
    return _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final recipes = snapshot.docs
              .map((doc) => RecipeModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid needing composite index
          recipes.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate); // Descending
          });
          return recipes;
        });
  }

  // Create recipe
  Future<String> createRecipe(RecipeModel recipe) async {
    DocumentReference docRef =
        await _firestore.collection('recipes').add(recipe.toMap());
    return docRef.id;
  }

  // Update recipe
  Future<void> updateRecipe(String recipeId, Map<String, dynamic> data) async {
    await _firestore.collection('recipes').doc(recipeId).update(data);
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  // ============ ANALYTICS ============

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get total users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.size;

      // Get total recipes
      QuerySnapshot recipesSnapshot =
          await _firestore.collection('recipes').get();
      int totalRecipes = recipesSnapshot.size;

      // Get active subscriptions
      QuerySnapshot activeSubsSnapshot = await _firestore
          .collection('users')
          .where('subscriptionStatus', isEqualTo: 'active')
          .where('subscriptionTier', whereIn: ['pro', 'elite']).get();
      int activeSubscriptions = activeSubsSnapshot.size;

      // Calculate revenue (mock for now)
      double revenue = activeSubscriptions * 15.0; // Average revenue

      return {
        'totalUsers': totalUsers,
        'totalRecipes': totalRecipes,
        'activeSubscriptions': activeSubscriptions,
        'revenue': revenue,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalRecipes': 0,
        'activeSubscriptions': 0,
        'revenue': 0.0,
      };
    }
  }

  // ============ SETTINGS ============

  // Save API settings
  Future<void> saveApiSettings(Map<String, dynamic> settings) async {
    await _firestore
        .collection('settings')
        .doc('api_config')
        .set(settings, SetOptions(merge: true));
  }

  // Get API settings
  Future<Map<String, dynamic>?> getApiSettings() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('settings').doc('api_config').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting API settings: $e');
      return null;
    }
  }
}
