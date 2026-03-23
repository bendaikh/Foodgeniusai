# 🔥 Firebase Storage Rules - Copy & Paste Guide

## Step-by-Step Instructions

### 1. Open Firebase Console
Go to: https://console.firebase.google.com/

### 2. Navigate to Storage Rules
- Select your project: **gourmetai**
- Click **Storage** in the left sidebar
- Click the **Rules** tab at the top
- You'll see the default rules editor

### 3. Copy These Rules

**Select ALL the text below and copy it:**

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Helper function to validate image file
    function isValidImage() {
      return request.resource.size < 5 * 1024 * 1024 // 5MB max
          && request.resource.contentType.matches('image/.*');
    }
    
    // Recipe images - users can upload/delete their own
    match /recipes/{userId}/{fileName} {
      allow read: if true; // Anyone can view recipes
      allow write: if isAuthenticated() && isOwner(userId) && isValidImage();
      allow delete: if isAuthenticated() && isOwner(userId);
    }
    
    // Profile pictures - users can manage their own
    match /profiles/{userId}/{fileName} {
      allow read: if true; // Anyone can view profiles
      allow write: if isAuthenticated() && isOwner(userId) && isValidImage();
      allow delete: if isAuthenticated() && isOwner(userId);
    }
    
    // Admin uploads (optional, configure later if needed)
    match /admin/{allPaths=**} {
      allow read: if true;
      allow write: if false; // Manually configure admin access later
    }
  }
}
```

### 4. Paste in Firebase Console
- Delete ALL existing rules in the editor
- Paste the rules you just copied
- Click **Publish** button (top right)

### 5. Verify Rules Are Active
You should see:
- "Rules successfully published" message
- The rules shown in the editor

---

## 🛡️ What These Rules Do

### Recipe Images (`/recipes/{userId}/{fileName}`)
- ✅ **Anyone** can view/download recipe images (public)
- ✅ **Authenticated users** can upload their own images
- ✅ **Only owners** can delete their images
- ✅ **Max file size**: 5 MB
- ✅ **Only images** allowed (jpg, png, gif, etc.)

### Profile Pictures (`/profiles/{userId}/{fileName}`)
- ✅ **Anyone** can view profile pictures
- ✅ **Authenticated users** can upload their own profile picture
- ✅ **Only owners** can delete their profile picture
- ✅ **Max file size**: 5 MB
- ✅ **Only images** allowed

### Admin Files (`/admin/{allPaths}`)
- ✅ **Anyone** can view admin files
- ❌ **Nobody** can upload (manual configuration needed later)

---

## ✅ That's It!

After publishing these rules, your storage is **fully secure** and ready to use!

Run your app and test the upload functionality.

---

## 🚨 If You See "Permission Denied"

1. Make sure you clicked **Publish** in Firebase Console
2. Check that user is **signed in** (authenticated)
3. Verify the user ID matches the folder path

---

## 📱 Ready to Test?

Run this in your project root:

```bash
flutter run
```

Then navigate to the Storage Test Page to verify uploads work!
