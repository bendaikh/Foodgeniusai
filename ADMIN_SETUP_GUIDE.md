# 🔐 GourmetAI Admin User Setup Guide

This guide shows you different ways to create an admin user in Firebase for your GourmetAI application.

## Quick Start (Recommended)

### Method 1: Use the Quick Admin Setup Page (Easiest!)

This is the simplest way to create an admin user:

1. **Run your Flutter app**
   ```bash
   flutter run
   ```

2. **Navigate to the Admin Setup page**
   - From the landing page, click the Admin icon in the top-right corner
   - OR manually navigate to the route: `/setup-admin`
   - OR add a debug button in your landing page (see below)

3. **Click "Create Admin Account"**
   - Default credentials will be created:
     - Email: `admin@gourmetai.com`
     - Password: `Admin123456`

4. **Login with admin credentials**
   - Go to `/admin` route
   - Login with the credentials above

### Method 2: Use the Database Seeder (Full Setup)

This method creates admin user + sample data:

1. **Run your Flutter app**
   ```bash
   flutter run
   ```

2. **Navigate to Database Seeder page**
   - You can add this route to your app's routes
   - Or create a navigation button

3. **Click "Run Seeder"**
   - This creates:
     - ✅ Admin user (admin@gourmetai.com)
     - ✅ 4 test users
     - ✅ 3 sample recipes
     - ✅ App settings

4. **Login as admin**
   - Email: `admin@gourmetai.com`
   - Password: `Admin123456`

## Advanced Methods

### Method 3: Run the Standalone Script

If you want to create an admin user programmatically:

1. **Run the script directly**
   ```bash
   dart run lib/utils/create_admin.dart
   ```

2. **The script will:**
   - Initialize Firebase
   - Create admin in Firebase Auth
   - Create admin document in Firestore
   - Set role to 'admin'

### Method 4: Use Firebase Console Manually

If you prefer manual setup:

1. **Create user in Firebase Authentication**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Authentication > Users
   - Click "Add User"
   - Email: `admin@gourmetai.com`
   - Password: `Admin123456` (or your choice)

2. **Create Firestore document**
   - Go to Firestore Database
   - Create a document in `users` collection
   - Document ID: (copy the UID from Authentication)
   - Add fields:
     ```
     uid: "copied-uid"
     email: "admin@gourmetai.com"
     name: "Admin User"
     role: "admin"  ⚠️ IMPORTANT!
     subscriptionTier: "elite"
     subscriptionStatus: "active"
     totalRecipesGenerated: 0
     apiUsageCount: 0
     createdAt: (timestamp)
     ```

## Adding Quick Access to Admin Setup

To make it easier to access the admin setup page, you can add a button to your landing page:

### Option A: Add Debug Icon (Development Only)

Add this to your `landing_page.dart` header:

```dart
// In _buildHeader method, add this after the admin icon:
IconButton(
  onPressed: () {
    Navigator.pushNamed(context, '/setup-admin');
  },
  icon: const Icon(Icons.settings, color: AppTheme.greyText),
  tooltip: 'Setup Admin',
),
```

### Option B: Add to Admin Login Page

You can add a link in the admin login page to redirect to setup:

```dart
TextButton(
  onPressed: () {
    Navigator.pushNamed(context, '/setup-admin');
  },
  child: const Text('Need to create admin account?'),
)
```

## Default Admin Credentials

After running any of the methods above, use these credentials to login:

- **Email:** `admin@gourmetai.com`
- **Password:** `Admin123456`

⚠️ **IMPORTANT:** Change these credentials in production!

## Verifying Admin Access

After creating the admin user:

1. **Check Firebase Authentication**
   - Go to Firebase Console > Authentication
   - You should see `admin@gourmetai.com` in the users list

2. **Check Firestore**
   - Go to Firebase Console > Firestore Database
   - Navigate to `users` collection
   - Find the document with your admin's UID
   - Verify `role` field is set to `"admin"`

3. **Test Login**
   - Navigate to `/admin` in your app
   - Login with admin credentials
   - You should have access to admin dashboard

## Troubleshooting

### Problem: "Email already in use"

**Solution:** The admin account already exists. Try:
1. Use the existing credentials to login
2. Or update the user's role in Firestore manually
3. Or delete the user from Firebase Auth and create again

### Problem: "Can't access admin features"

**Solution:** Check the `role` field in Firestore:
1. Go to Firestore Database
2. Find your user document in `users` collection
3. Verify `role` field is exactly `"admin"` (lowercase)
4. If not, update it manually

### Problem: "No such document"

**Solution:** The Firestore document wasn't created:
1. Run the admin setup script again
2. Or manually create the document (see Method 4 above)

## Security Notes

### Production Considerations:

1. **Change Default Password**
   - Don't use `Admin123456` in production
   - Use a strong, unique password

2. **Use Environment Variables**
   - Store admin email in environment variables
   - Don't hardcode credentials in source code

3. **Enable MFA**
   - Enable Multi-Factor Authentication in Firebase
   - Protect admin accounts with extra security

4. **Firestore Security Rules**
   - Ensure only admins can access admin collections
   - Example rule:
     ```javascript
     match /users/{userId} {
       allow read: if request.auth != null;
       allow write: if request.auth.uid == userId 
                    || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
     }
     ```

## Quick Reference

| Method | Speed | Setup Complexity | Creates Sample Data |
|--------|-------|------------------|---------------------|
| Quick Admin Setup Page | ⚡ Fast | 🟢 Easy | ❌ No |
| Database Seeder | 🚀 Medium | 🟢 Easy | ✅ Yes |
| Standalone Script | ⚡ Fast | 🟡 Medium | ❌ No |
| Firebase Console | 🐌 Slow | 🔴 Hard | ❌ No |

## Need Help?

If you're still having issues:

1. Check Firebase Console for errors
2. Check Flutter console for error messages
3. Verify Firebase is properly initialized in `main.dart`
4. Ensure you have the correct Firebase configuration in `firebase_options.dart`

---

**Happy Cooking with GourmetAI! 👨‍🍳**
