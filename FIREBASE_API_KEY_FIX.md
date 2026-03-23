# 🔧 Firebase API Key Error - Fix Guide

## Error Message:
```
❌ Error creating admin: [firebase_auth/api-key-not-valid.-please-pass-a-valid-api-key.]
```

## Root Cause:
Your Firebase Web API key is either:
1. Restricted and not allowing Authentication requests
2. Invalid or regenerated
3. Authentication service is not enabled

## 🚀 Solution (Step by Step):

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **gourmetai-c432b**

### Step 2: Enable Authentication

1. In the left sidebar, click **Authentication**
2. Click **Get Started** (if not already enabled)
3. Go to **Sign-in method** tab
4. Enable **Email/Password** sign-in provider:
   - Click on "Email/Password"
   - Toggle **Enable** to ON
   - Click **Save**

### Step 3: Check API Key Restrictions

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **gourmetai-c432b**
3. In the left sidebar, click **APIs & Services** > **Credentials**
4. Find your Web API Key: `AIzaSyClG1zFNb6sfLC0yKO-Mmbawqq6ReqazpI`
5. Click on it to edit

### Step 4: Configure API Key (Critical!)

There are two options:

#### Option A: Remove Restrictions (Development/Testing)
1. Under **Application restrictions**, select **None**
2. Under **API restrictions**, select **Don't restrict key**
3. Click **Save**

⚠️ This is less secure but good for development

#### Option B: Add Proper Restrictions (Recommended for Production)
1. Under **Application restrictions**:
   - Select **HTTP referrers (web sites)**
   - Add these referrers:
     ```
     http://localhost:*
     http://127.0.0.1:*
     https://gourmetai-c432b.web.app
     https://gourmetai-c432b.firebaseapp.com
     ```

2. Under **API restrictions**:
   - Select **Restrict key**
   - Enable these APIs:
     - ✅ Identity Toolkit API
     - ✅ Cloud Firestore API
     - ✅ Firebase Storage API
     - ✅ Token Service API

3. Click **Save**

### Step 5: Verify Firebase Services are Enabled

1. Go back to [Firebase Console](https://console.firebase.google.com/)
2. Check that these services are enabled:

   **✅ Authentication:**
   - Go to Authentication
   - Should show "Email/Password" as enabled

   **✅ Firestore Database:**
   - Go to Firestore Database
   - Should be in either Test Mode or Production Mode
   - If not created, click "Create database"

   **✅ Storage:**
   - Go to Storage
   - Should be initialized
   - If not, click "Get started"

### Step 6: Wait for Changes to Propagate

After making changes in Google Cloud Console:
- Wait **5-10 minutes** for changes to propagate
- Changes are not instant!

### Step 7: Restart Your App

```bash
# Stop the current app (Ctrl+C in terminal)
# Then restart:
flutter run -d chrome
```

## 🔄 Alternative: Regenerate Firebase Configuration

If the above doesn't work, regenerate your Firebase config:

### Method 1: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI if not installed
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Reconfigure Firebase
flutterfire configure

# This will regenerate firebase_options.dart with fresh API keys
```

### Method 2: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click the gear icon ⚙️ > **Project settings**
3. Scroll down to **Your apps**
4. Click on your Web app (🌐)
5. Copy the Firebase configuration

6. Update `lib/firebase_options.dart` with the new values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR-NEW-API-KEY-HERE',
  appId: 'YOUR-APP-ID',
  messagingSenderId: 'YOUR-SENDER-ID',
  projectId: 'gourmetai-c432b',
  authDomain: 'gourmetai-c432b.firebaseapp.com',
  storageBucket: 'gourmetai-c432b.firebasestorage.app',
  measurementId: 'YOUR-MEASUREMENT-ID',
);
```

## ✅ Verification Steps

After fixing:

1. **Test Firebase Connection:**
   ```bash
   flutter run -d chrome
   ```

2. **Check Console Output:**
   - Should see: `✅ Firebase initialized successfully`
   - Should NOT see: API key errors

3. **Test Admin Creation:**
   - Click the green ➕ icon (Create Admin)
   - Should see: `✅ Admin account created successfully!`

## 🐛 Still Not Working?

If you're still getting errors, check:

### Debug Checklist:

- [ ] Email/Password authentication is enabled in Firebase Console
- [ ] API key restrictions are configured correctly
- [ ] Waited 5-10 minutes after changing API key settings
- [ ] Restarted the Flutter app after changes
- [ ] Firestore Database is created and accessible
- [ ] No billing issues in Firebase Console

### Get More Information:

1. **Check Firebase Console Logs:**
   - Go to Firebase Console
   - Click "Analytics" or "Usage and billing"
   - Look for error messages

2. **Enable Debug Logging:**
   ```dart
   // Add this to main.dart before Firebase.initializeApp()
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   print('Firebase project: ${Firebase.app().options.projectId}');
   print('Firebase apiKey: ${Firebase.app().options.apiKey}');
   ```

3. **Test API Key Directly:**
   Open this URL in your browser (replace with your API key):
   ```
   https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyClG1zFNb6sfLC0yKO-Mmbawqq6ReqazpI
   ```
   
   - If it returns JSON: API key works
   - If it returns error: API key is restricted/invalid

## 📝 Quick Fix Summary

**Most Common Fix:**
1. Go to Google Cloud Console > Credentials
2. Click on your Web API Key
3. Under "Application restrictions", select **None**
4. Under "API restrictions", select **Don't restrict key**
5. Click **Save**
6. Wait 5 minutes
7. Restart app: `flutter run -d chrome`

---

**Need more help?** Check the Firebase Console for any error messages or billing issues.
