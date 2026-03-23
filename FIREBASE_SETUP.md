# GourmetAI - Firebase Backend Setup Guide

## 🔥 Firebase Implementation Plan

### 1. Firebase Setup

#### A. Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name it "GourmetAI"
4. Enable Google Analytics (optional)

#### B. Add Firebase to Flutter App

**Install Firebase CLI:**
```bash
npm install -g firebase-tools
firebase login
```

**Install FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
```

**Configure Firebase:**
```bash
flutterfire configure
```

### 2. Update pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core
  firebase_core: ^2.24.2
  
  # Authentication
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
  
  # Database
  cloud_firestore: ^4.13.6
  
  # Storage (for images)
  firebase_storage: ^11.5.6
  
  # Cloud Functions
  cloud_functions: ^4.5.12
  
  # State Management
  provider: ^6.1.1
  
  # Other utilities
  google_fonts: ^6.1.0
```

### 3. Database Schema (Firestore)

#### Collections Structure:

**users** (collection)
```json
{
  "userId": "auto-generated-id",
  "email": "user@example.com",
  "name": "John Doe",
  "subscriptionTier": "free|pro|elite",
  "subscriptionStatus": "active|cancelled|expired",
  "subscriptionStartDate": "2024-03-11T00:00:00Z",
  "subscriptionEndDate": "2024-04-11T00:00:00Z",
  "createdAt": "2024-03-11T00:00:00Z",
  "totalRecipesGenerated": 42,
  "apiUsageCount": 150
}
```

**recipes** (collection)
```json
{
  "recipeId": "auto-generated-id",
  "userId": "user-id-reference",
  "title": "Creamy Mushroom Asparagus Chicken Penne",
  "description": "A delicious pasta dish...",
  "ingredients": [
    {
      "name": "Penne Pasta",
      "amount": "8 oz",
      "grams": 227
    }
  ],
  "instructions": [
    {
      "stepNumber": 1,
      "title": "Cook the Pasta",
      "description": "Bring a large pot..."
    }
  ],
  "nutrition": {
    "calories": 450,
    "protein": 40,
    "carbs": 70,
    "fats": 25
  },
  "difficulty": "intermediate",
  "prepTime": 15,
  "cookTime": 15,
  "totalTime": 30,
  "servings": 2,
  "cuisine": "Italian",
  "mealType": "dinner",
  "dietary": ["none"],
  "imageUrl": "https://storage.googleapis.com/...",
  "createdAt": "2024-03-11T00:00:00Z",
  "views": 0,
  "saves": 0,
  "isPublic": true
}
```

**subscriptions** (collection)
```json
{
  "subscriptionId": "auto-generated-id",
  "userId": "user-id-reference",
  "plan": "gourmet_pro",
  "status": "active|cancelled|past_due",
  "amount": 12.00,
  "currency": "USD",
  "billingPeriod": "monthly|yearly",
  "stripeCustomerId": "cus_xxx",
  "stripeSubscriptionId": "sub_xxx",
  "currentPeriodStart": "2024-03-11T00:00:00Z",
  "currentPeriodEnd": "2024-04-11T00:00:00Z",
  "cancelAtPeriodEnd": false,
  "createdAt": "2024-03-11T00:00:00Z"
}
```

**payments** (collection)
```json
{
  "paymentId": "auto-generated-id",
  "userId": "user-id-reference",
  "subscriptionId": "subscription-id-reference",
  "amount": 12.00,
  "currency": "USD",
  "status": "success|failed|pending",
  "paymentMethod": "card",
  "cardBrand": "visa",
  "cardLast4": "4242",
  "stripePaymentIntentId": "pi_xxx",
  "transactionDate": "2024-03-11T00:00:00Z",
  "createdAt": "2024-03-11T00:00:00Z"
}
```

**api_keys** (collection - admin only)
```json
{
  "keyId": "auto-generated-id",
  "provider": "openai|anthropic|google",
  "apiKey": "encrypted-key",
  "model": "gpt-4",
  "maxTokens": 2000,
  "temperature": 0.7,
  "isActive": true,
  "usageCount": 1547,
  "costToday": 127.50,
  "dailyLimit": 10000,
  "createdAt": "2024-03-11T00:00:00Z",
  "updatedAt": "2024-03-11T00:00:00Z"
}
```

**analytics** (collection)
```json
{
  "analyticsId": "auto-generated-id",
  "date": "2024-03-11",
  "totalUsers": 2847,
  "newUsers": 342,
  "activeUsers": 1948,
  "recipesGenerated": 542,
  "revenue": 1420.00,
  "conversionRate": 0.048,
  "avgSessionDuration": 754,
  "popularCuisines": {
    "italian": 847,
    "asian": 634,
    "mexican": 478
  }
}
```

### 4. Firebase Security Rules

**Firestore Rules** (`firestore.rules`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Recipes collection
    match /recipes/{recipeId} {
      allow read: if resource.data.isPublic == true || 
                     isOwner(resource.data.userId) || 
                     isAdmin();
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.userId) || isAdmin();
      allow delete: if isOwner(resource.data.userId) || isAdmin();
    }
    
    // Subscriptions - read only for users, full access for admin
    match /subscriptions/{subscriptionId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow write: if isAdmin();
    }
    
    // Payments - read only for users, full access for admin
    match /payments/{paymentId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow write: if isAdmin();
    }
    
    // API Keys - admin only
    match /api_keys/{keyId} {
      allow read, write: if isAdmin();
    }
    
    // Analytics - admin only
    match /analytics/{analyticsId} {
      allow read, write: if isAdmin();
    }
  }
}
```

### 5. Firebase Cloud Functions

**Initialize Functions:**
```bash
firebase init functions
cd functions
npm install
```

**functions/index.js:**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { OpenAI } = require('openai');

admin.initializeApp();
const db = admin.firestore();

// Generate Recipe using OpenAI
exports.generateRecipe = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const userId = context.auth.uid;
  const { craving, mealType, dietary, servings, portion } = data;
  
  try {
    // Get user subscription
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    // Check subscription limits
    if (userData.subscriptionTier === 'free' && userData.apiUsageCount >= 10) {
      throw new functions.https.HttpsError('permission-denied', 'Free tier limit reached');
    }
    
    // Get OpenAI API key
    const apiKeyDoc = await db.collection('api_keys')
      .where('provider', '==', 'openai')
      .where('isActive', '==', true)
      .limit(1)
      .get();
    
    if (apiKeyDoc.empty) {
      throw new functions.https.HttpsError('internal', 'API key not configured');
    }
    
    const apiKey = apiKeyDoc.docs[0].data().apiKey;
    const openai = new OpenAI({ apiKey });
    
    // Generate recipe
    const prompt = `Create a detailed recipe for ${craving}. 
      Meal type: ${mealType}
      Dietary restrictions: ${dietary}
      Servings: ${servings}
      Portion size: ${portion}
      
      Return a JSON object with:
      - title
      - description
      - ingredients (array with name, amount, grams)
      - instructions (array with stepNumber, title, description)
      - nutrition (calories, protein, carbs, fats)
      - difficulty
      - prepTime, cookTime, totalTime
      - cuisine`;
    
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
    });
    
    const recipe = JSON.parse(completion.choices[0].message.content);
    
    // Save recipe to Firestore
    const recipeRef = await db.collection('recipes').add({
      ...recipe,
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      views: 0,
      saves: 0,
      isPublic: true
    });
    
    // Update user usage
    await db.collection('users').doc(userId).update({
      apiUsageCount: admin.firestore.FieldValue.increment(1),
      totalRecipesGenerated: admin.firestore.FieldValue.increment(1)
    });
    
    return { recipeId: recipeRef.id, recipe };
    
  } catch (error) {
    console.error('Error generating recipe:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Handle Stripe Webhook
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  // Stripe webhook handler for subscription events
  // Implementation details...
});

// Daily Analytics Aggregation
exports.aggregateAnalytics = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    // Aggregate daily analytics
    // Implementation details...
  });
```

### 6. Implementation Steps

#### Step 1: Install Dependencies
```bash
cd gourmetai
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage provider
flutter pub get
```

#### Step 2: Initialize Firebase in Flutter

Create `lib/services/firebase_service.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

#### Step 3: Update main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const GourmetAIApp());
}
```

### 7. Cost Estimation (Monthly)

**Firebase (Free Tier Limits):**
- Firestore: 50K reads, 20K writes per day (FREE)
- Authentication: Unlimited (FREE)
- Storage: 5GB (FREE)
- Functions: 2M invocations (FREE)

**Paid Plans (if needed):**
- Firestore: $0.06 per 100K reads
- Storage: $0.026 per GB
- Functions: $0.40 per million invocations

**OpenAI API:**
- GPT-4: ~$0.03 per 1K tokens (~$0.10 per recipe)
- DALL-E 3: $0.040 per image
- Estimated: $300-500/month for 3,000 recipes

### 8. Next Steps

1. Create Firebase project
2. Install Firebase CLI and FlutterFire
3. Run `flutterfire configure`
4. Add dependencies to pubspec.yaml
5. Set up Firestore collections
6. Implement authentication
7. Create Cloud Functions
8. Set up Stripe for payments
9. Deploy and test

Would you like me to help you implement any specific part?
