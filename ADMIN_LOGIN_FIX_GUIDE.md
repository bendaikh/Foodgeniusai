# Fix Admin Login Issue - SOLUTION

## Problem
You're getting "Access denied. Admin privileges required." when trying to log in with:
- Email: `admin@gourmetai.com`
- Password: `Admin123456`

## Root Cause
The admin account exists in Firebase Authentication, but it doesn't have the `role: 'admin'` field in the Firestore database. The app checks for this field to verify admin privileges.

---

## SOLUTION - Choose One Method:

### Method 1: Use the Fix Admin Page (EASIEST)

1. **Access the Fix Admin Page**:
   - Navigate to: `http://localhost:PORT/#/fix-admin` (or your domain)
   - For example: `http://localhost:56789/#/fix-admin`

2. **Click "Fix Admin Role"** button
   - This will update the existing admin@gourmetai.com account to have admin privileges

3. **Try logging in again** at `/admin`

---

### Method 2: Use Firebase Console

1. **Go to Firebase Console**:
   - Visit: https://console.firebase.google.com/project/gourmetai-c432b/firestore

2. **Navigate to Firestore Database**:
   - Click on "Firestore Database" in the left sidebar
   - Find the `users` collection

3. **Find the admin user**:
   - Look for the document where `email` = `admin@gourmetai.com`
   - Click on that document

4. **Update the role field**:
   - Find the `role` field
   - If it doesn't exist, click "Add field"
   - Set: `role` = `admin` (as a string)
   - If it exists but says `user`, change it to `admin`

5. **Also update these fields** (optional but recommended):
   - `subscriptionTier` = `elite`
   - `subscriptionStatus` = `active`
   - `name` = `Admin User`

6. **Save and try logging in again**

---

### Method 3: Use the Quick Admin Setup Page

1. **Navigate to**: `http://localhost:PORT/#/setup-admin`

2. **Click "Create Default Admin Account"**
   - If the account already exists, it will update the role to admin
   - If it doesn't exist, it will create it with proper admin privileges

3. **Try logging in again**

---

## How to Access These Pages

When your app is running (using `flutter run -d chrome`), you can access:

- **Fix Admin Page**: Add `#/fix-admin` to your URL
  - Example: `http://localhost:56789/#/fix-admin`

- **Setup Admin Page**: Add `#/setup-admin` to your URL
  - Example: `http://localhost:56789/#/setup-admin`

- **Admin Login Page**: Add `#/admin` to your URL
  - Example: `http://localhost:56789/#/admin`

---

## What the Fix Does

The fix updates your Firestore database document for `admin@gourmetai.com` to include:

```json
{
  "uid": "user_id_here",
  "email": "admin@gourmetai.com",
  "name": "Admin User",
  "role": "admin",              // ← This is the critical field!
  "subscriptionTier": "elite",
  "subscriptionStatus": "active",
  "totalRecipesGenerated": 0,
  "apiUsageCount": 0,
  "createdAt": "timestamp"
}
```

The `role: 'admin'` field is what the app checks when you try to log in.

---

## Verification Steps

After applying the fix:

1. **Navigate to** `/admin` or `#/admin`
2. **Enter credentials**:
   - Email: `admin@gourmetai.com`
   - Password: `Admin123456`
3. **Click "Sign In"**
4. **Should redirect to Admin Dashboard** ✅

---

## If It Still Doesn't Work

1. **Clear browser cache and cookies**
   - Press `Ctrl + Shift + Delete`
   - Clear cached data

2. **Check browser console for errors**:
   - Press `F12` to open developer tools
   - Check the Console tab for any error messages

3. **Verify Firebase connection**:
   - Make sure you're connected to the internet
   - Check if other Firebase features work

4. **Verify the user exists in Firestore**:
   - Go to Firebase Console
   - Check Firestore Database → users collection
   - Confirm admin@gourmetai.com exists

---

## Files Created/Modified

- ✅ `lib/screens/fix_admin_page.dart` - New page to fix admin role
- ✅ `lib/utils/fix_admin_role.dart` - Utility functions for fixing admin
- ✅ `lib/main.dart` - Added `/fix-admin` route

---

## Quick Steps Summary

1. Run your app: `flutter run -d chrome`
2. Navigate to: `http://localhost:PORT/#/fix-admin`
3. Click "Fix Admin Role" or "Create Admin Account"
4. Go to: `http://localhost:PORT/#/admin`
5. Log in with admin@gourmetai.com / Admin123456
6. ✅ Success!

---

## Understanding the Login Flow

```
User enters credentials → Firebase Auth validates
    ↓
Login successful → Check Firestore for user document
    ↓
Read 'role' field from user document
    ↓
If role = 'admin' → Allow access to Admin Dashboard
If role ≠ 'admin' → Show "Access denied" error
```

The issue was that the `role` field was either missing or set to `'user'` instead of `'admin'`.

---

Last Updated: March 27, 2026
Status: ✅ Fix Available
