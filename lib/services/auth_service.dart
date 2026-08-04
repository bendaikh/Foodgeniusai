import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/dev_flags.dart';

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
    // TEST ONLY — see lib/config/dev_flags.dart
    if (kTestSubscriptionBypass) return true;
    if (userData == null) return false;
    final tier = userData['subscriptionTier'] as String? ?? 'free';
    final status = userData['subscriptionStatus'] as String? ?? 'active';
    return status == 'active' && tier != 'free';
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = currentUser;
    if (user == null || user.isAnonymous) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
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

      await _ensureUserDocument(
        result.user!,
        email: email,
        name: name,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Continue with Google (popup on web, provider flow on mobile).
  Future<UserCredential> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      final result = await _signInWithOAuthProvider(provider);
      await _ensureUserDocument(result.user!);
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'cancelled-popup-request' ||
          e.code == 'popup-closed-by-user') {
        throw 'Google sign-in was cancelled.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Google sign-in failed. Please try again.';
    }
  }

  /// Continue with Apple.
  Future<UserCredential> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final result = await _signInWithOAuthProvider(provider);
      await _ensureUserDocument(result.user!);
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'cancelled-popup-request' ||
          e.code == 'popup-closed-by-user') {
        throw 'Apple sign-in was cancelled.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Apple sign-in failed. Please try again.';
    }
  }

  Future<UserCredential> _signInWithOAuthProvider(AuthProvider provider) async {
    final anonymousUser = _auth.currentUser;
    if (anonymousUser != null && anonymousUser.isAnonymous) {
      try {
        return await anonymousUser.linkWithProvider(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use' ||
            e.code == 'provider-already-linked') {
          if (kIsWeb) {
            return await _auth.signInWithPopup(provider);
          }
          return await _auth.signInWithProvider(provider);
        }
        rethrow;
      }
    }

    if (kIsWeb) {
      return await _auth.signInWithPopup(provider);
    }
    return await _auth.signInWithProvider(provider);
  }

  Future<void> _ensureUserDocument(
    User user, {
    String? email,
    String? name,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final existing = await docRef.get();
    if (existing.exists) return;

    await docRef.set({
      'uid': user.uid,
      'email': email ?? user.email ?? '',
      'name': name ?? user.displayName ?? 'Food Genius',
      'subscriptionTier': 'free',
      'subscriptionStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'totalRecipesGenerated': 0,
      'apiUsageCount': 0,
      'monthlyGenerationsUsed': 0,
      'generationPeriodStart': FieldValue.serverTimestamp(),
      'role': 'user',
    }, SetOptions(merge: true));
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
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please enable it in Firebase Authentication.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
