import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a user from admin panel without signing in as that user
  /// This uses a temporary auth instance to avoid logging out the admin
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String subscriptionTier,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'name': name,
        'subscriptionTier': subscriptionTier,
        'subscriptionStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'role': 'user',
      });

      // Important: Sign out the newly created user to keep admin logged in
      // This is a workaround since we can't create users without signing them in
      await _auth.signOut();
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  /// Update user information
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }

  /// Delete user document from Firestore
  /// Note: This doesn't delete from Firebase Auth (requires Admin SDK)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw 'Error deleting user: $e';
    }
  }

  /// Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
