import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// Standalone script to create an admin user in Firebase
/// Run this once to set up your admin account
/// 
/// Usage:
/// 1. Run this file directly: dart run lib/utils/create_admin.dart
/// 2. Or add a button in your app to call createAdminUser()

Future<void> main() async {
  print('🔐 FoodGeniusAI Admin User Setup');
  print('==============================\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
    
    // Create admin user
    await createAdminUser(
      email: 'admin@gourmetai.com',
      password: 'Admin123456',
      name: 'Admin User',
    );
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Create an admin user in Firebase Auth and Firestore
Future<void> createAdminUser({
  required String email,
  required String password,
  required String name,
}) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  print('\n📝 Creating admin account...');
  print('   Email: $email');
  
  try {
    // Step 1: Create user in Firebase Authentication
    print('\n1️⃣  Creating Firebase Auth user...');
    UserCredential userCredential;
    
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('   ✅ Firebase Auth user created');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('   ⚠️  User already exists in Firebase Auth');
        print('   🔄 Attempting to sign in and update Firestore...');
        
        // Sign in to get the user
        userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('   ✅ Signed in successfully');
      } else {
        throw Exception('Firebase Auth error: ${e.message}');
      }
    }
    
    final userId = userCredential.user!.uid;
    print('   📋 User ID: $userId');
    
    // Step 2: Create/Update user document in Firestore
    print('\n2️⃣  Creating/Updating Firestore document...');
    
    final userDoc = await firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      // Update existing document to admin
      await firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'name': name,
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('   ✅ Updated existing user to admin role');
    } else {
      // Create new document
      await firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'name': name,
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'role': 'admin',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('   ✅ Created new admin user document');
    }
    
    // Step 3: Sign out
    await auth.signOut();
    print('\n3️⃣  ✅ Signed out (ready for login)');
    
    // Success message
    print('\n' + '=' * 50);
    print('✅ ADMIN USER SETUP COMPLETE!');
    print('=' * 50);
    print('\n📧 Login Credentials:');
    print('   Email:    $email');
    print('   Password: $password');
    print('\n🎉 You can now login as admin!');
    print('=' * 50 + '\n');
    
  } catch (e) {
    print('\n❌ Error creating admin user: $e');
    rethrow;
  }
}

/// Alternative: Create admin with custom credentials
Future<void> createCustomAdmin() async {
  print('Enter admin details:');
  
  // In a real Flutter app, you'd use TextFields
  // For now, using default values
  await createAdminUser(
    email: 'admin@gourmetai.com',
    password: 'Admin123456',
    name: 'Admin User',
  );
}
