# Firebase Setup - Manual Configuration Steps

## ✅ Step 1: Create Firebase Project (DO THIS NOW)

1. Go to: https://console.firebase.google.com/
2. Click **"Add project"**
3. Project name: `GourmetAI`
4. Click Continue
5. Disable Google Analytics (or enable if you want)
6. Click **"Create project"**
7. Wait for creation, then click **"Continue"**

---

## ✅ Step 2: Add Web App to Firebase

1. In your Firebase project dashboard, click the **Web icon** `</>`
2. App nickname: `GourmetAI Web`
3. ✅ Check **"Also set up Firebase Hosting"**
4. Click **"Register app"**
5. **IMPORTANT**: Copy the firebaseConfig object (we'll need it!)

It should look like this:
```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "gourmetai-xxxxx.firebaseapp.com",
  projectId: "gourmetai-xxxxx",
  storageBucket: "gourmetai-xxxxx.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:xxxxx"
};
```

6. Click **"Continue to console"**

---

## ✅ Step 3: Enable Authentication

1. In Firebase console, click **"Build"** → **"Authentication"**
2. Click **"Get started"**
3. Click **"Sign-in method"** tab
4. Enable **"Email/Password"**
   - Click on it
   - Toggle "Enable"
   - Click Save
5. (Optional) Enable **"Google"** sign-in for easier auth

---

## ✅ Step 4: Create Firestore Database

1. In Firebase console, click **"Build"** → **"Firestore Database"**
2. Click **"Create database"**
3. Select **"Start in test mode"** (we'll add security rules later)
4. Choose location: **"us-central"** (or closest to you)
5. Click **"Enable"**

---

## ✅ Step 5: Enable Storage

1. In Firebase console, click **"Build"** → **"Storage"**
2. Click **"Get started"**
3. Click **"Next"** (keep test mode)
4. Choose location: same as Firestore
5. Click **"Done"**

---

## ✅ Step 6: Configure Flutter App

After completing steps 1-5 above, **SEND ME** your `firebaseConfig` object.

I will then:
1. Create the Firebase configuration files for your Flutter app
2. Set up authentication service
3. Create Firestore service for database operations
4. Connect your app to Firebase

---

## 📋 What to Send Me

Copy and paste your Firebase config from Step 2. It looks like this:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

**Just paste that here, and I'll set everything up for you!**

---

## ⏱️ Time Estimate

- Steps 1-2: 5 minutes
- Step 3: 2 minutes
- Step 4: 2 minutes  
- Step 5: 2 minutes
- **Total: ~11 minutes**

Then I'll handle all the code integration! 🚀

---

## 🎯 After Firebase Setup

Once you send me the config, I will create:

1. **`lib/firebase_options.dart`** - Firebase configuration
2. **`lib/services/auth_service.dart`** - Authentication service
3. **`lib/services/firestore_service.dart`** - Database operations
4. **`lib/models/`** - Data models (User, Recipe, etc.)
5. Update **`main.dart`** - Initialize Firebase
6. Update screens to use real data

---

## 🔥 Ready?

Complete steps 1-5 above, then send me your firebaseConfig!
