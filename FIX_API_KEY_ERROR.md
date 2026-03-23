# 🔑 Fixing "api-key-not-valid" Error

## 🐛 **The Problem:**

You're getting `firebase_auth/api-key-not-valid` error when trying to create the admin account. This happens because:

1. Email/Password authentication is not enabled in Firebase Console
2. OR the API key restrictions need to be configured

---

## ✅ **Solution: Enable Email/Password Authentication**

### **Step 1: Go to Firebase Console**
https://console.firebase.google.com/project/gourmetai-c432b/authentication/providers

### **Step 2: Enable Email/Password Sign-In**

1. Click on **"Authentication"** in the left sidebar
2. Click on **"Sign-in method"** tab at the top
3. Look for **"Email/Password"** in the list of providers
4. Click on **"Email/Password"**
5. Toggle **"Enable"** to ON
6. Click **"Save"**

**Screenshot reference:**
```
Sign-in providers
┌─────────────────────────────────────┐
│ Email/Password          [Enable ✓] │  ← Click here
│ Phone                              │
│ Google                             │
│ Anonymous                          │
└─────────────────────────────────────┘
```

---

## 🔄 **After Enabling:**

### **Step 1: Refresh Your App**
Press `F5` in your browser or press `R` in Flutter terminal

### **Step 2: Try Creating Admin Again**
1. Go back to login page
2. Click **"Create Admin Account"** button
3. Should now work! ✅

### **Step 3: Log In**
```
Email: admin@gourmetai.com
Password: Admin123456
```

---

## 🎯 **Alternative: Manual Admin Creation**

If the button still doesn't work, create the admin manually in Firebase Console:

### **Step 1: Go to Authentication**
https://console.firebase.google.com/project/gourmetai-c432b/authentication/users

### **Step 2: Add User**
1. Click **"Add user"** button
2. Enter:
   ```
   Email: admin@gourmetai.com
   Password: Admin123456
   ```
3. Click **"Add user"**

### **Step 3: Make User Admin in Firestore**
1. Go to Firestore Database
2. Open **"users"** collection
3. Find the document with **email: "admin@gourmetai.com"**
4. Edit the document
5. Change/Add field: `role: "admin"`
6. Save

### **Step 4: Log In**
Now you can log in with admin@gourmetai.com / Admin123456

---

## 📋 **Quick Checklist:**

- [ ] Go to Firebase Console → Authentication
- [ ] Click "Sign-in method" tab
- [ ] Enable "Email/Password" provider
- [ ] Click Save
- [ ] Refresh your app
- [ ] Try creating admin again OR create manually
- [ ] Log in with admin@gourmetai.com / Admin123456

---

## 🔍 **Verify It's Enabled:**

In Firebase Console → Authentication → Sign-in method, you should see:

```
Email/Password    Enabled ✓
```

If it says "Disabled", click it and enable it!

---

## ✅ **Expected Result:**

After enabling Email/Password authentication:
- ✅ "Create Admin Account" button will work
- ✅ Admin account will be created
- ✅ You can log in successfully
- ✅ Access to admin panel!

---

## 🚨 **Still Not Working?**

If you still get errors after enabling Email/Password:

1. **Clear browser cache** (Ctrl+Shift+Delete)
2. **Restart Flutter app** (press `q` then `flutter run -d chrome` again)
3. **Create admin manually** in Firebase Console (see Alternative above)

---

## 🎉 **Quick Link:**

**Enable Email/Password Authentication:**
https://console.firebase.google.com/project/gourmetai-c432b/authentication/providers

Just click the link, enable Email/Password, save, and try again!
