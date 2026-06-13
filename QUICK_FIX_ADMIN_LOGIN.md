# 🚨 QUICK FIX - Admin Login Issue

## Your Problem
Login with `admin@gourmetai.com` / `Admin123456` shows:
> "Access denied. Admin privileges required."

## Root Cause
The admin account is missing the `role: 'admin'` field in Firestore.

---

## ✅ SOLUTION (Choose One)

### Option 1: Use Fix Admin Page (RECOMMENDED)

**Step 1**: Make sure your app is running
```bash
flutter run -d chrome
```

**Step 2**: In the browser that opens, modify the URL to:
```
http://localhost:PORT/#/fix-admin
```

Or if you see a URL like `http://localhost:62512/`, change it to:
```
http://localhost:62512/#/fix-admin
```

**Step 3**: Click the **"Fix Admin Role"** button

**Step 4**: Go to admin login:
```
http://localhost:PORT/#/admin
```

**Step 5**: Log in with:
- Email: `admin@gourmetai.com`
- Password: `Admin123456`

---

### Option 2: Use Firebase Console (If app won't load)

1. Go to: https://console.firebase.google.com/project/gourmetai-c432b/firestore
2. Click "Firestore Database"
3. Find the `users` collection
4. Find the document where `email` = `admin@gourmetai.com`
5. Click on that document
6. Find or add the `role` field
7. Set `role` = `admin` (as a string type)
8. Click Save
9. Try logging in again

---

### Option 3: Use Setup Page

Navigate to:
```
http://localhost:PORT/#/setup-admin
```

Click "Create Default Admin Account" - it will update the role if account exists.

---

## Available URLs in Your App

When running locally, you can access:

| Page | URL |
|------|-----|
| Fix Admin | `http://localhost:PORT/#/fix-admin` |
| Admin Login | `http://localhost:PORT/#/admin` |
| Setup Admin | `http://localhost:PORT/#/setup-admin` |
| Test Firebase | `http://localhost:PORT/#/test-firebase` |

Replace `PORT` with your actual port number (check the terminal).

---

## What Gets Fixed

The fix adds this field to your Firestore user document:

```json
{
  "role": "admin"  // ← This field is required!
}
```

Without this field, the app thinks you're a regular user, not an admin.

---

## Quick Debug

**Check if the user exists in Firestore**:
1. Go to Firebase Console
2. Firestore Database → `users` collection
3. Look for `admin@gourmetai.com`

**If user doesn't exist**: Use Option 3 above to create it
**If user exists but no `role` field**: Use Option 2 to add it
**If user exists with `role: 'user'`**: Use Option 1 or 2 to change it to `'admin'`

---

## After Fix

Once fixed, the admin login flow:
1. Go to `/admin`
2. Enter credentials
3. ✅ Redirects to Admin Dashboard

---

Created: March 27, 2026
Files: `ADMIN_LOGIN_FIX_GUIDE.md` (detailed), `lib/screens/fix_admin_page.dart` (fix page)
