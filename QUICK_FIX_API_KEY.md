# 🔥 Firebase API Key Error - QUICK FIX

## ❌ Your Error:
```
[firebase_auth/api-key-not-valid.-please-pass-a-valid-api-key.]
```

## ✅ Quick Fix (5 Minutes):

### Step 1: Go to Google Cloud Console
1. Open: https://console.cloud.google.com/
2. Select project: **gourmetai-c432b**

### Step 2: Find Your API Key
1. Click: **APIs & Services** → **Credentials**
2. Find: `Browser key (auto created by Firebase)` or your Web API Key
   - Should start with: `AIzaSyClG1z...`

### Step 3: Remove Restrictions (EASIEST FIX)
1. Click on the API Key
2. Under **Application restrictions**: Select **None**
3. Under **API restrictions**: Select **Don't restrict key**
4. Click **SAVE**

### Step 4: Enable Identity Toolkit API
1. In Google Cloud Console, go to: **APIs & Services** → **Library**
2. Search for: **Identity Toolkit API**
3. Click on it and click **ENABLE**

### Step 5: Wait & Restart
1. Wait **5 minutes** for changes to apply
2. Stop your Flutter app (Ctrl+C)
3. Restart: `flutter run -d chrome`

### Step 6: Test
1. Click the orange 🔬 icon (Test Firebase) on your landing page
2. Click "Run Connection Tests"
3. Should see all green checkmarks ✅

---

## 🧪 Test Your Firebase Connection

I've added a Firebase Test page to your app:

**Access it:**
- Click the orange 🔬 icon in the top-right corner
- OR navigate to `/test-firebase` route

**What it does:**
- Tests Firebase initialization
- Tests Authentication connection
- Tests Firestore connection
- **Tries to create a test user** (this will show if API key works)

---

## 🎯 After Fixing, Create Admin:

1. Click the green ➕ icon (Create Admin)
2. Wait for success message
3. Login with:
   - Email: `admin@gourmetai.com`
   - Password: `Admin123456`

---

## 📚 More Details:

See the complete guide: [FIREBASE_API_KEY_FIX.md](./FIREBASE_API_KEY_FIX.md)

---

## 🔍 Icons Added to Landing Page:

- 🔬 **Orange Science Icon**: Test Firebase Connection
- ⚙️ **Grey Admin Icon**: Admin Login
- ➕ **Green Person Icon**: Create Admin Account

---

**Good luck! The most common fix is just removing API key restrictions in Google Cloud Console. 🚀**
