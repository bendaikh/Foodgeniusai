# 🚨 ADMIN LOGIN FIX - START HERE

## The Problem
```
Login Failed: "Access denied. Admin privileges required."
Email: admin@gourmetai.com
Password: Admin123456
```

## The Solution (3 Steps)

### Step 1: Navigate to Fix Page
```
http://localhost:PORT/#/fix-admin
```
Or if deployed:
```
https://gourmetai-c432b.web.app/#/fix-admin
```

### Step 2: Click Button
Click the big green button that says:
```
🛠️ Fix Admin Role
```

### Step 3: Login Again
Go to:
```
http://localhost:PORT/#/admin
```
Enter:
- Email: `admin@gourmetai.com`
- Password: `Admin123456`

## ✅ Done!

---

## Alternative: Use Firebase Console

1. Visit: https://console.firebase.google.com/project/gourmetai-c432b/firestore
2. Open: `users` collection
3. Find: `admin@gourmetai.com` document
4. Edit: Set `role` field to `admin` (as string)
5. Save and try logging in again

---

## Need Help?

Read the detailed guides:
- `ADMIN_LOGIN_FIX_SUMMARY.md` - Complete overview
- `ADMIN_LOGIN_FIX_GUIDE.md` - Step-by-step instructions
- `QUICK_FIX_ADMIN_LOGIN.md` - Quick reference

---

**What was wrong**: Missing `role: 'admin'` field in Firestore
**What the fix does**: Adds/updates the role field to 'admin'
**Status**: ✅ Fix built and ready to use
