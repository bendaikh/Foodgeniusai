import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Database Seeder (like Laravel migrations)
/// Run this once to populate your database with initial data
class FirebaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Run all seeders
  Future<void> runAllSeeders() async {
    print('🌱 Starting database seeding...');
    
    try {
      await seedUsers();
      await seedRecipes();
      await seedSettings();
      
      print('✅ Database seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding database: $e');
      rethrow;
    }
  }

  /// Seed Users Collection
  Future<void> seedUsers() async {
    print('👥 Seeding users...');

    final users = [
      {
        'email': 'admin@gourmetai.com',
        'password': 'Admin123456',
        'name': 'Admin User',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'role': 'admin',
        'totalRecipesGenerated': 0,
        'apiUsageCount': 0,
      },
      {
        'email': 'john.doe@example.com',
        'password': 'Test123456',
        'name': 'John Doe',
        'subscriptionTier': 'pro',
        'subscriptionStatus': 'active',
        'role': 'user',
        'totalRecipesGenerated': 42,
        'apiUsageCount': 150,
      },
      {
        'email': 'sarah.smith@example.com',
        'password': 'Test123456',
        'name': 'Sarah Smith',
        'subscriptionTier': 'elite',
        'subscriptionStatus': 'active',
        'role': 'user',
        'totalRecipesGenerated': 87,
        'apiUsageCount': 320,
      },
      {
        'email': 'alex.johnson@example.com',
        'password': 'Test123456',
        'name': 'Alex Johnson',
        'subscriptionTier': 'free',
        'subscriptionStatus': 'active',
        'role': 'user',
        'totalRecipesGenerated': 12,
        'apiUsageCount': 25,
      },
      {
        'email': 'emily.brown@example.com',
        'password': 'Test123456',
        'name': 'Emily Brown',
        'subscriptionTier': 'pro',
        'subscriptionStatus': 'suspended',
        'role': 'user',
        'totalRecipesGenerated': 56,
        'apiUsageCount': 200,
      },
    ];

    for (var userData in users) {
      try {
        // Create user in Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: userData['email'] as String,
          password: userData['password'] as String,
        );

        final userId = userCredential.user!.uid;

        // Create user document in Firestore
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': userData['email'],
          'name': userData['name'],
          'subscriptionTier': userData['subscriptionTier'],
          'subscriptionStatus': userData['subscriptionStatus'],
          'role': userData['role'],
          'totalRecipesGenerated': userData['totalRecipesGenerated'],
          'apiUsageCount': userData['apiUsageCount'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Sign out immediately to prevent auto-login
        await _auth.signOut();

        print('  ✅ Created user: ${userData['email']}');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('  ⏭️  User already exists: ${userData['email']}');
        } else {
          print('  ❌ Error creating user ${userData['email']}: $e');
        }
      }
    }

    print('👥 Users seeding completed!');
  }

  /// Seed Recipes Collection
  Future<void> seedRecipes() async {
    print('🍳 Seeding recipes...');

    // Get first user to assign recipes to
    final usersSnapshot = await _firestore.collection('users').limit(1).get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('  ⚠️  No users found. Skipping recipe seeding.');
      return;
    }

    final userId = usersSnapshot.docs.first.id;

    final recipes = [
      {
        'title': 'Classic Italian Pasta Carbonara',
        'description': 'A creamy, authentic Italian pasta dish with bacon, eggs, and parmesan cheese.',
        'difficulty': 'intermediate',
        'prepTime': 10,
        'cookTime': 15,
        'totalTime': 25,
        'servings': 4,
        'cuisine': 'Italian',
        'mealType': 'Dinner',
        'dietary': [''],
        'ingredients': [
          {'name': 'Spaghetti', 'amount': '400g'},
          {'name': 'Bacon', 'amount': '200g'},
          {'name': 'Eggs', 'amount': '4'},
          {'name': 'Parmesan cheese', 'amount': '100g'},
          {'name': 'Black pepper', 'amount': '1 tsp'},
        ],
        'instructions': [
          {'step': 1, 'description': 'Cook pasta according to package instructions'},
          {'step': 2, 'description': 'Fry bacon until crispy'},
          {'step': 3, 'description': 'Beat eggs with parmesan'},
          {'step': 4, 'description': 'Mix hot pasta with bacon and egg mixture'},
          {'step': 5, 'description': 'Season with black pepper and serve'},
        ],
        'nutrition': {
          'calories': 550,
          'protein': 25,
          'carbs': 60,
          'fat': 22,
        },
        'views': 1234,
        'saves': 456,
        'isPublic': true,
      },
      {
        'title': 'Grilled Chicken Caesar Salad',
        'description': 'Fresh romaine lettuce with grilled chicken, croutons, and homemade Caesar dressing.',
        'difficulty': 'easy',
        'prepTime': 15,
        'cookTime': 10,
        'totalTime': 25,
        'servings': 2,
        'cuisine': 'American',
        'mealType': 'Lunch',
        'dietary': ['High Protein'],
        'ingredients': [
          {'name': 'Chicken breast', 'amount': '2 pieces'},
          {'name': 'Romaine lettuce', 'amount': '1 head'},
          {'name': 'Parmesan cheese', 'amount': '50g'},
          {'name': 'Croutons', 'amount': '1 cup'},
          {'name': 'Caesar dressing', 'amount': '100ml'},
        ],
        'instructions': [
          {'step': 1, 'description': 'Season and grill chicken breast'},
          {'step': 2, 'description': 'Chop romaine lettuce'},
          {'step': 3, 'description': 'Toss lettuce with dressing'},
          {'step': 4, 'description': 'Top with sliced chicken and croutons'},
          {'step': 5, 'description': 'Garnish with parmesan'},
        ],
        'nutrition': {
          'calories': 450,
          'protein': 35,
          'carbs': 25,
          'fat': 22,
        },
        'views': 890,
        'saves': 234,
        'isPublic': true,
      },
      {
        'title': 'Vegan Buddha Bowl',
        'description': 'A nutritious and colorful bowl with quinoa, roasted vegetables, and tahini dressing.',
        'difficulty': 'easy',
        'prepTime': 10,
        'cookTime': 25,
        'totalTime': 35,
        'servings': 2,
        'cuisine': 'International',
        'mealType': 'Lunch',
        'dietary': ['Vegan', 'Gluten-Free'],
        'ingredients': [
          {'name': 'Quinoa', 'amount': '1 cup'},
          {'name': 'Sweet potato', 'amount': '1 large'},
          {'name': 'Chickpeas', 'amount': '1 can'},
          {'name': 'Kale', 'amount': '2 cups'},
          {'name': 'Tahini', 'amount': '3 tbsp'},
          {'name': 'Avocado', 'amount': '1'},
        ],
        'instructions': [
          {'step': 1, 'description': 'Cook quinoa according to package'},
          {'step': 2, 'description': 'Roast sweet potato and chickpeas'},
          {'step': 3, 'description': 'Massage kale with olive oil'},
          {'step': 4, 'description': 'Arrange ingredients in bowl'},
          {'step': 5, 'description': 'Drizzle with tahini dressing'},
        ],
        'nutrition': {
          'calories': 520,
          'protein': 15,
          'carbs': 65,
          'fat': 20,
        },
        'views': 2100,
        'saves': 890,
        'isPublic': true,
      },
    ];

    for (var recipeData in recipes) {
      await _firestore.collection('recipes').add({
        ...recipeData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('  ✅ Created recipe: ${recipeData['title']}');
    }

    print('🍳 Recipes seeding completed!');
  }

  /// Seed Settings Collection
  Future<void> seedSettings() async {
    print('⚙️  Seeding settings...');

    // API Configuration
    await _firestore.collection('settings').doc('api_config').set({
      'openaiApiKey': '',
      'openaiModel': 'gpt-4',
      'maxTokens': 2000,
      'temperature': 0.7,
      'anthropicApiKey': '',
      'anthropicModel': 'claude-3-opus-20240229',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('  ✅ Created API configuration');

    // App Settings
    await _firestore.collection('settings').doc('app_config').set({
      'appName': 'GourmetAI',
      'maintenanceMode': false,
      'allowRegistration': true,
      'featuredRecipesEnabled': true,
      'maxFreeRecipes': 10,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('  ✅ Created app configuration');

    // Email Templates
    await _firestore.collection('settings').doc('email_templates').set({
      'welcomeEmailEnabled': true,
      'welcomeEmailSubject': 'Welcome to GourmetAI!',
      'welcomeEmailBody': 'Thank you for joining GourmetAI...',
      'resetPasswordSubject': 'Reset Your Password',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('  ✅ Created email templates');

    print('⚙️  Settings seeding completed!');
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    print('🗑️  WARNING: Clearing all data...');

    // Clear users
    final usersSnapshot = await _firestore.collection('users').get();
    for (var doc in usersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Clear recipes
    final recipesSnapshot = await _firestore.collection('recipes').get();
    for (var doc in recipesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Clear settings
    final settingsSnapshot = await _firestore.collection('settings').get();
    for (var doc in settingsSnapshot.docs) {
      await doc.reference.delete();
    }

    print('🗑️  All data cleared!');
  }
}
