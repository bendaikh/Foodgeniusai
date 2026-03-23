# 🎨 Firebase Storage - Visual Flow

## 📱 Image Upload Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERACTION                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  User taps "Upload Image" button in ImageUploadWidget       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ImagePickerHelper.showImageSourceDialog()                  │
│  ┌─────────────────────────────────────────────┐            │
│  │  ○ Gallery                                   │            │
│  │  ○ Camera                                    │            │
│  └─────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Image Picker Plugin                                         │
│  • Compresses image (85% quality)                           │
│  • Resizes to max 1920x1080                                 │
│  • Returns File object                                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  StorageService.uploadRecipeImage()                         │
│  • Generates unique filename                                │
│  • Creates path: recipes/{userId}/{filename}                │
│  • Uploads to Firebase Storage                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Firebase Storage                                            │
│  • Validates rules (auth, ownership, size, type)            │
│  • Stores image                                             │
│  • Returns download URL                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Download URL returned to app                               │
│  https://firebasestorage.googleapis.com/v0/b/...            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Save URL to Firestore                                      │
│  recipes/{recipeId}/imageUrl = "https://..."                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Display image in UI using Image.network(url)               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Storage Structure

```
Firebase Storage
└── gourmetai.appspot.com (your bucket)
    │
    ├── recipes/
    │   ├── user_abc123/
    │   │   ├── recipe_1710123456789.jpg
    │   │   ├── recipe_1710123567890.jpg
    │   │   └── recipe_1710123678901.jpg
    │   │
    │   ├── user_def456/
    │   │   ├── recipe_1710234567890.jpg
    │   │   └── recipe_1710345678901.jpg
    │   │
    │   └── user_xyz789/
    │       └── recipe_1710456789012.jpg
    │
    ├── profiles/
    │   ├── user_abc123/
    │   │   └── profile.jpg
    │   │
    │   ├── user_def456/
    │   │   └── profile.jpg
    │   │
    │   └── user_xyz789/
    │       └── profile.jpg
    │
    └── admin/
        └── (admin files - configure later)
```

---

## 🔐 Security Flow

```
User uploads image
        │
        ▼
┌─────────────────────────────────┐
│ Is user authenticated?          │
│ (request.auth != null)          │
└─────────────────────────────────┘
        │ YES
        ▼
┌─────────────────────────────────┐
│ Does user own this path?        │
│ (request.auth.uid == userId)    │
└─────────────────────────────────┘
        │ YES
        ▼
┌─────────────────────────────────┐
│ Is file size < 5MB?             │
│ Is it an image?                 │
└─────────────────────────────────┘
        │ YES
        ▼
┌─────────────────────────────────┐
│ ✅ UPLOAD ALLOWED               │
└─────────────────────────────────┘

Any NO? → ❌ PERMISSION DENIED
```

---

## 📦 Code Structure

```
┌────────────────────────────────────────────────────────────┐
│                     YOUR APP                                │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────┐      │
│  │  SCREENS (UI Layer)                             │      │
│  │  • recipe_form_page.dart                        │      │
│  │  • my_creations_page.dart                       │      │
│  │  • storage_test_page.dart                       │      │
│  └─────────────────────────────────────────────────┘      │
│                      ↓ uses                                │
│  ┌─────────────────────────────────────────────────┐      │
│  │  WIDGETS (Reusable Components)                  │      │
│  │  • ImageUploadWidget                            │      │
│  └─────────────────────────────────────────────────┘      │
│                      ↓ uses                                │
│  ┌─────────────────────────────────────────────────┐      │
│  │  UTILS (Helper Functions)                       │      │
│  │  • ImagePickerHelper                            │      │
│  │    - pickImageFromGallery()                     │      │
│  │    - pickImageFromCamera()                      │      │
│  └─────────────────────────────────────────────────┘      │
│                      ↓ returns File                        │
│  ┌─────────────────────────────────────────────────┐      │
│  │  SERVICES (Business Logic)                      │      │
│  │  • StorageService                               │      │
│  │    - uploadRecipeImage()                        │      │
│  │    - deleteImageByUrl()                         │      │
│  └─────────────────────────────────────────────────┘      │
│                      ↓ uses                                │
└────────────────────────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────┐
│              FIREBASE STORAGE SDK                           │
│  • firebase_storage package                                │
│  • Handles upload/download/delete                          │
└────────────────────────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────┐
│              FIREBASE CLOUD                                 │
│  • Stores your images                                      │
│  • Applies security rules                                  │
│  • Returns download URLs                                   │
└────────────────────────────────────────────────────────────┘
```

---

## 🎯 Quick Reference

### 1. Pick Image
```dart
final file = await ImagePickerHelper.pickImageFromGallery();
```

### 2. Upload Image
```dart
final url = await StorageService().uploadRecipeImage(file, userId);
```

### 3. Save URL to Firestore
```dart
await FirebaseFirestore.instance
    .collection('recipes')
    .doc(recipeId)
    .update({'imageUrl': url});
```

### 4. Display Image
```dart
Image.network(recipe.imageUrl)
```

### 5. Delete Image
```dart
await StorageService().deleteImageByUrl(imageUrl);
```

---

## 📋 Checklist for Going Live

- [ ] Set up Firebase Storage Rules (see FIREBASE_RULES_SETUP.md)
- [ ] Test upload on Android device
- [ ] Test camera functionality
- [ ] Test gallery functionality
- [ ] Test delete functionality
- [ ] Verify images appear in Firebase Console
- [ ] Add error handling for network failures
- [ ] Add loading states in UI
- [ ] Test with different image sizes
- [ ] Test with different file formats (jpg, png, etc.)
- [ ] Monitor storage usage in Firebase Console

---

## 🎉 Ready to Use!

Follow the steps in **STORAGE_QUICKSTART.md** to get started!
