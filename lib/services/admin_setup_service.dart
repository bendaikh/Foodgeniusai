import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Setup Service
/// Use this to create the initial admin account
class AdminSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create the admin account in Firebase Auth
  /// Call this once to set up your admin user
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔐 Creating admin account...');

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create admin user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'name': name,
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'role': 'admin', // This is the important part!
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out immediately
      await _auth.signOut();

      print('✅ Admin account created successfully!');
      print('   Email: $email');
      print('   Password: $password');
      print('   You can now log in with these credentials.');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠️  Admin account already exists with this email');
        
        // Try to update existing user to admin
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userId = querySnapshot.docs.first.id;
            await _firestore.collection('users').doc(userId).update({
              'role': 'admin',
              'name': name,
              'subscriptionTier': 'elite',
            });
            print('✅ Updated existing user to admin role');
          }
        } catch (updateError) {
          print('❌ Error updating user: $updateError');
        }
      } else {
        print('❌ Error creating admin: $e');
        rethrow;
      }
    }
  }

  /// Quick setup: Create default admin account
  Future<void> createDefaultAdmin() async {
    await createAdminAccount(
      email: 'admin@gourmetai.com',
      password: 'Admin123456',
      name: 'Admin User',
    );
  }
}
