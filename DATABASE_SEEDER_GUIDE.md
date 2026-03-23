# 🌱 Firebase Database Seeder - Like Laravel Migrations!

## 🎉 What Is This?

This is a **database seeder** for Firebase, similar to Laravel's migrations and seeders. It populates your Firestore database with initial/demo data.

---

## ✅ **What Was Created**

### 1. **FirebaseSeeder Service** (`lib/services/firebase_seeder.dart`)
- Seeds users collection (5 users including 1 admin)
- Seeds recipes collection (3 sample recipes)
- Seeds settings collection (API config, app settings, email templates)
- Can clear all data (use with caution!)

### 2. **Database Seeder Page** (`lib/admin/screens/database_seeder_page.dart`)
- Beautiful UI to run the seeder
- Live logs showing progress
- One-click seeding
- Warning for data clearing

### 3. **Added to Admin Dashboard**
- New menu item: "Database Seeder 🌱"
- Easy access from admin panel

---

## 🚀 **How to Use**

### **Step 1: Run Your App**
```bash
flutter run -d chrome
```

### **Step 2: Go to Admin Panel**
- Navigate to admin login
- Or if already logged in, go to admin dashboard

### **Step 3: Click "Database Seeder" in the sidebar**
Look for the menu item with the 🌱 icon

### **Step 4: Click "Run Seeder" Button**
- Wait for the process to complete
- Watch the logs in real-time
- You'll see messages like:
  ```
  🌱 Starting database seeding...
  👥 Seeding users...
    ✅ Created user: admin@gourmetai.com
    ✅ Created user: john.doe@example.com
    ...
  🍳 Seeding recipes...
    ✅ Created recipe: Classic Italian Pasta Carbonara
    ...
  ⚙️ Seeding settings...
    ✅ Created API configuration
  ✅ Database seeding completed successfully!
  ```

### **Step 5: Check Firebase Console**
Go to: https://console.firebase.google.com/project/gourmetai-c432b/firestore

**You should now see:**
- 📁 `users` collection (5 documents)
- 📁 `recipes` collection (3 documents)  
- 📁 `settings` collection (3 documents)

---

## 📊 **What Gets Seeded**

### **👥 Users Collection (5 users)**

| Name | Email | Password | Role | Tier | Recipes |
|------|-------|----------|------|------|---------|
| Admin User | admin@gourmetai.com | Admin123456 | admin | elite | 0 |
| John Doe | john.doe@example.com | Test123456 | user | pro | 42 |
| Sarah Smith | sarah.smith@example.com | Test123456 | user | elite | 87 |
| Alex Johnson | alex.johnson@example.com | Test123456 | user | free | 12 |
| Emily Brown | emily.brown@example.com | Test123456 | user | pro | 56 |

### **🍳 Recipes Collection (3 recipes)**
1. **Classic Italian Pasta Carbonara** - Italian, Dinner, Intermediate
2. **Grilled Chicken Caesar Salad** - American, Lunch, Easy
3. **Vegan Buddha Bowl** - International, Lunch, Easy, Vegan

### **⚙️ Settings Collection (3 documents)**
1. **api_config** - OpenAI and Anthropic API configuration
2. **app_config** - App settings, maintenance mode, features
3. **email_templates** - Welcome email, password reset templates

---

## 🎯 **Use Cases**

### **1. Fresh Setup**
Starting a new project? Run the seeder to get instant demo data!

### **2. Development/Testing**
Need test data? Run the seeder to populate your dev environment!

### **3. Resetting Database**
Want to start fresh? Clear all data, then run seeder again!

### **4. Demo/Presentation**
Showing your app to someone? Have realistic demo data ready!

---

## 🔑 **Login Credentials (After Seeding)**

### **Admin Account:**
```
Email: admin@gourmetai.com
Password: Admin123456
```

### **Test User Accounts:**
```
Email: john.doe@example.com
Email: sarah.smith@example.com
Email: alex.johnson@example.com
Email: emily.brown@example.com

All passwords: Test123456
```

---

## ⚠️ **Important Notes**

### **Duplicate Prevention**
- If a user already exists (same email), it will be **skipped**
- You'll see: `⏭️ User already exists: email@example.com`
- No data will be overwritten

### **Clear All Data**
- **USE WITH CAUTION!**
- Deletes all users, recipes, and settings from Firestore
- Does NOT delete from Firebase Authentication
- Requires confirmation dialog

### **Firebase Authentication**
- Users are created in both Auth and Firestore
- You can log in with any of the seeded accounts
- Admin account has `role: 'admin'` in Firestore

---

## 📱 **Screenshots / What You'll See**

### **Admin Sidebar:**
```
┌─────────────────────────┐
│  Dashboard              │
│  Users                  │
│  Recipes                │
│  Payments               │
│  API Settings           │
│  Analytics              │
│ ─────────────────────── │
│  🌱 Database Seeder     │
│     Seed Data           │
│  Settings               │
│  Logout                 │
└─────────────────────────┘
```

### **Seeder Page:**
```
┌─────────────────────────────────────────────┐
│  🌱 Database Seeder                         │
│  Populate your Firebase database with       │
│  initial data (like Laravel migrations)     │
│                                             │
│  What will be seeded:                       │
│  👥 Users Collection - 5 users (1 admin)    │
│  🍳 Recipes Collection - 3 sample recipes   │
│  ⚙️ Settings Collection - API config, etc.  │
│                                             │
│  [Run Seeder]  [Clear All Data]            │
│                                             │
│  Logs:                                      │
│  ┌─────────────────────────────────────┐   │
│  │ 🌱 Starting database seeding...      │   │
│  │ ✅ Created user: admin@gourmetai.com │   │
│  │ ✅ Created user: john.doe@...        │   │
│  │ ...                                  │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  🔑 Seeded User Credentials:                │
│  Admin: admin@gourmetai.com / Admin123456   │
│  Users: test@example.com / Test123456       │
└─────────────────────────────────────────────┘
```

---

## 🔄 **How It Works**

### **1. Run Seeder Button Click**
```
User clicks "Run Seeder"
     ↓
FirebaseSeeder.runAllSeeders()
     ↓
├─ seedUsers()
│  ├─ Create user in Firebase Auth
│  ├─ Create user document in Firestore
│  └─ Sign out (to keep admin logged in)
│
├─ seedRecipes()
│  └─ Create recipe documents in Firestore
│
└─ seedSettings()
   └─ Create settings documents in Firestore
```

### **2. Collections Appear in Firebase**
```
Before Seeding:
Firestore Database
└── (empty)

After Seeding:
Firestore Database
├── users (5)
├── recipes (3)
└── settings (3)
```

---

## 🐛 **Troubleshooting**

### **"Email already in use" errors**
→ Users already exist  
→ They will be skipped, no problem!  
→ If you want fresh data, click "Clear All Data" first

### **Seeder button doesn't appear**
→ Make sure you're in the admin panel  
→ Check the sidebar for "Database Seeder 🌱"  
→ If not there, rebuild the app

### **Collections still not showing**
→ Wait a few seconds, then refresh Firebase Console  
→ Check the logs in the seeder page  
→ If there are errors, they'll show in red

### **Can't log in with seeded accounts**
→ Make sure seeder completed successfully  
→ Check Firebase Console → Authentication → Users  
→ Verify users were created

---

## 🎉 **You're Done!**

Your Firebase database now has:
- ✅ 5 users (including 1 admin)
- ✅ 3 sample recipes
- ✅ Complete settings configuration
- ✅ Ready to use immediately!

---

## 🚀 **Next Steps**

1. **Test the seeded data:**
   - Go to Users page in admin panel
   - See all 5 users
   - Edit, view, or delete them

2. **Log in as different users:**
   - Try logging in as admin
   - Try logging in as regular users
   - See different subscription tiers

3. **Check recipes:**
   - Go to Recipes page
   - See the 3 seeded recipes
   - Create more recipes!

4. **Customize the seeder:**
   - Edit `lib/services/firebase_seeder.dart`
   - Add more users, recipes, or collections
   - Run it again!

---

## 📝 **Files Created**

- `lib/services/firebase_seeder.dart` - Seeder service
- `lib/admin/screens/database_seeder_page.dart` - Seeder UI
- Updated: `lib/admin/screens/admin_dashboard.dart` - Added menu item

---

## 🎉 **Go Seed Your Database Now!**

1. Run your app
2. Go to Admin Panel
3. Click "Database Seeder"
4. Click "Run Seeder"
5. Watch the magic happen!
6. Check Firebase Console to see your collections!

**Your Firebase database will be populated in seconds!** 🚀
