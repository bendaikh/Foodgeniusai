import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// True when the user has a real (non-anonymous) account.
  bool get isAuthenticatedUser {
    final user = currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Whether the user has an active paid subscription.
  bool hasPaidSubscription(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    final tier = userData['subscriptionTier'] as String? ?? 'free';
    final status = userData['subscriptionStatus'] as String? ?? 'active';
    return status == 'active' && tier != 'free';
  }

  /// Live stream of the signed-in user's Firestore profile (null for guests).
  Stream<Map<String, dynamic>?> get userProfileStream {
    return authStateChanges.asyncExpand((user) {
      if (user == null || user.isAnonymous) {
        return Stream.value(null);
      }
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? doc.data() : null);
    });
  }

  /// Ensures the user is authenticated before recipe generation.
  /// Guests are signed in anonymously so Firestore can load AI settings.
  Future<User> ensureAuthForRecipeGeneration() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null) {
      return existingUser;
    }

    try {
      final result = await _auth.signInAnonymously();
      final user = result.user;
      if (user == null) {
        throw Exception('Anonymous sign-in failed');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw Exception(
          'Guest recipe generation is disabled. Enable Anonymous sign-in in Firebase Authentication, or log in with an account.',
        );
      }
      throw Exception('Unable to start recipe generation: ${e.message}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential result;
      final anonymousUser = _auth.currentUser;

      if (anonymousUser != null && anonymousUser.isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        result = await anonymousUser.linkWithCredential(credential);
      } else {
        result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'name': name,
        'subscriptionTier': 'free',
        'subscriptionStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'role': 'user',
      }, SetOptions(merge: true));

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        return userDoc.get('role') == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
