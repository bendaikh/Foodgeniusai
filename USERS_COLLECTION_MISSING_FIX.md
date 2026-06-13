# 🚨 USERS COLLECTION MISSING - FIX GUIDE

## Problem
The `users` collection in Firestore was deleted or doesn't exist, but the admin account exists in Firebase Authentication.

## Solution: Force Recreate Admin User

### Step 1: Hot Reload Your App

In the terminal where `flutter run -d chrome` is running, press:
```
r
```
This will hot reload the app with the new Force Create Admin page.

### Step 2: Navigate to Force Create Admin Page

In your browser, change the URL to:
```
http://localhost:62512/#/force-admin
```

(Your port is 62512 based on the terminal output)

### Step 3: Follow the 2-Step Process

**Step 1 in the page**: Click "Get Admin User UID"
- This will sign in with admin@gourmetai.com and get the User UID

**Step 2 in the page**: Click "Create Firestore Document"
- This will create the `users` collection and add the admin document with `role: 'admin'`

### Step 4: Verify in Firestore

1. Go back to Firebase Console → Firestore
2. You should now see the `users` collection
3. Inside it, you'll see the admin user document with:
   - `email`: admin@gourmetai.com
   - `role`: admin ✅

### Step 5: Try Logging In

Navigate to:
```
http://localhost:62512/#/admin
```

Log in with:
- Email: `admin@gourmetai.com`
- Password: `Admin123456`

---

## Alternative: Create Manually in Firebase Console

If the above doesn't work due to Firestore security rules, create it manually:

### Step 1: Get User UID from Authentication

1. Go to: https://console.firebase.google.com/project/gourmetai-c432b/authentication/users
2. Find `admin@gourmetai.com` in the list
3. Copy the **User UID** (long string like `xYz123AbC...`)

### Step 2: Create Users Collection in Firestore

1. Go to: https://console.firebase.google.com/project/gourmetai-c432b/firestore
2. Click **"+ Start collection"**
3. Collection ID: `users`
4. Click "Next"

### Step 3: Add Admin Document

1. **Document ID**: Paste the User UID you copied from Step 1
2. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `uid` | string | (paste User UID) |
| `email` | string | `admin@gourmetai.com` |
| `name` | string | `Admin User` |
| `role` | string | `admin` |
| `subscriptionTier` | string | `elite` |
| `subscriptionStatus` | string | `active` |
| `totalRecipesGenerated` | number | `0` |
| `apiUsageCount` | number | `0` |
| `createdAt` | timestamp | (click "Use current date/time") |

3. Click "Save"

### Step 4: Try Logging In

Go to your app and try logging in again!

---

## Why This Happened

The `users` collection can be deleted if:
1. Someone manually deleted it from Firestore Console
2. A script or seeder deleted all documents
3. Firestore rules were changed and prevented writes

The Firebase Authentication user still exists, but without the Firestore document, the app can't verify admin role.

---

## Quick Actions

**Hot reload**: In terminal, press `r`
**Force Admin Page**: `http://localhost:62512/#/force-admin`
**Admin Login**: `http://localhost:62512/#/admin`

---

Last Updated: March 27, 2026
Status: ✅ Fix page created at `/force-admin`
