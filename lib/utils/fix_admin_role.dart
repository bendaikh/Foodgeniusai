import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick Fix: Update admin@gourmetai.com to have admin role
/// Run this once to fix the admin account
Future<void> fixAdminRole() async {
  try {
    print('🔧 Fixing admin role...');
    
    final firestore = FirebaseFirestore.instance;
    
    // Find user by email
    final querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: 'admin@gourmetai.com')
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      print('❌ No user found with email admin@gourmetai.com');
      print('   Please create the admin account first using AdminSetupService.createDefaultAdmin()');
      return;
    }
    
    final userDoc = querySnapshot.docs.first;
    final userId = userDoc.id;
    
    // Update the user document to have admin role
    await firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'name': 'Admin User',
      'subscriptionTier': 'elite',
      'subscriptionStatus': 'active',
    });
    
    print('✅ Admin role updated successfully!');
    print('   User ID: $userId');
    print('   Email: admin@gourmetai.com');
    print('   Role: admin');
    print('');
    print('You can now log in with:');
    print('   Email: admin@gourmetai.com');
    print('   Password: Admin123456');
    
  } catch (e) {
    print('❌ Error fixing admin role: $e');
    rethrow;
  }
}

/// Alternative: Create admin account if it doesn't exist
Future<void> createOrFixAdmin() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  const email = 'admin@gourmetai.com';
  const password = 'Admin123456';
  const name = 'Admin User';
  
  try {
    print('🔐 Creating/Fixing admin account...');
    
    // Try to create the account
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final userId = userCredential.user!.uid;
      
      // Create admin user document
      await firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'name': name,
        'role': 'admin',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await auth.signOut();
      
      print('✅ New admin account created!');
      
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠️  Account exists, updating role...');
        await fixAdminRole();
      } else {
        rethrow;
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}
