# 📇 Firebase Storage - Quick Reference Card

Keep this open while coding! All essential info in one place.

---

## 🔥 Essential Links

### Firebase Console
- **Console**: https://console.firebase.google.com/
- **Project**: gourmetai
- **Storage Rules**: Console → Storage → Rules
- **Storage Files**: Console → Storage → Files

### Documentation
- **Start Here**: `README_STORAGE.md`
- **Setup Rules**: `FIREBASE_RULES_SETUP.md`
- **Test Guide**: `QUICK_TEST_GUIDE.md`
- **All Docs**: `00_DOCUMENTATION_INDEX.md`

---

## 📦 Dependencies

```yaml
firebase_storage: ^11.5.6
image_picker: ^1.2.1
```

---

## 🎯 Quick Code Snippets

### 1. Import Statements

```dart
import 'package:gourmetai/services/storage_service.dart';
import 'package:gourmetai/utils/image_picker_helper.dart';
import 'package:gourmetai/widgets/image_upload_widget.dart';
```

---

### 2. Pick Image

```dart
// From Gallery
final file = await ImagePickerHelper.pickImageFromGallery();

// From Camera
final file = await ImagePickerHelper.pickImageFromCamera();

// Multiple Images
final files = await ImagePickerHelper.pickMultipleImages();

// Show Dialog (Camera or Gallery)
final file = await ImagePickerHelper.showImageSourceDialog(context);
```

---

### 3. Upload Image

```dart
final storageService = StorageService();

// Recipe Image (auto-organized)
final url = await storageService.uploadRecipeImage(file, userId);

// Profile Picture
final url = await storageService.uploadProfilePicture(file, userId);

// Custom Path
final url = await storageService.uploadImage(file, 'custom/path/image.jpg');
```

---

### 4. Delete Image

```dart
// Delete by URL
await storageService.deleteImageByUrl(imageUrl);

// Delete by Path
await storageService.deleteImageByPath('recipes/user123/image.jpg');
```

---

### 5. Using ImageUploadWidget

```dart
// In your StatefulWidget
String? _recipeImageUrl;

// In your build method
ImageUploadWidget(
  userId: currentUserId,
  isRecipeImage: true,
  initialImageUrl: _recipeImageUrl,
  onImageUploaded: (imageUrl) {
    setState(() {
      _recipeImageUrl = imageUrl;
    });
  },
  height: 250,
  width: double.infinity,
)
```

---

### 6. Display Image

```dart
// Simple
Image.network(recipe.imageUrl)

// With Loading
Image.network(
  recipe.imageUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
)

// With Error & Placeholder
recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
  ? Image.network(recipe.imageUrl!)
  : Icon(Icons.restaurant, size: 64)
```

---

### 7. Save to Firestore

```dart
// RecipeModel already has imageUrl field!
RecipeModel recipe = RecipeModel(
  title: 'My Recipe',
  description: 'Description',
  imageUrl: _recipeImageUrl,  // ← Add this
  // ... other fields
);

await firestoreService.createRecipe(recipe);
```

---

### 8. Complete Upload Flow

```dart
Future<void> uploadAndSaveRecipe() async {
  // 1. Pick image
  final file = await ImagePickerHelper.pickImageFromGallery();
  if (file == null) return;
  
  // 2. Upload to Storage
  final storageService = StorageService();
  final imageUrl = await storageService.uploadRecipeImage(
    file,
    userId: currentUserId,
  );
  
  // 3. Create recipe with image URL
  final recipe = RecipeModel(
    title: _titleController.text,
    imageUrl: imageUrl,  // Include URL
    // ... other fields
  );
  
  // 4. Save to Firestore
  await firestoreService.createRecipe(recipe);
  
  // 5. Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Recipe created!')),
  );
}
```

---

## 🗂️ Storage Structure

```
Firebase Storage
└── recipes/
    └── {userId}/
        └── recipe_{timestamp}.jpg

└── profiles/
    └── {userId}/
        └── profile.jpg
```

---

## 🔒 Security Rules (MUST SET UP!)

**Location**: Firebase Console → Storage → Rules

**Status**: ⬜ Not Set / ⏳ In Progress / ✅ Published

**To set up**: See `FIREBASE_RULES_SETUP.md`

---

## 📊 Storage Limits (Blaze Free Tier)

- **Storage**: 5 GB
- **Download**: 1 GB/day
- **Uploads**: 20,000/day
- **Downloads**: 50,000/day

---

## 🚨 Common Errors

### "Permission Denied"
→ Set up Storage Rules in Firebase Console

### "File too large"
→ Images auto-compress to 5MB max

### "Camera not working"
→ Test on real device, not emulator

### "Image not uploading"
→ Check internet connection
→ Verify Firebase initialized
→ Check Storage rules published

---

## 🧪 Quick Test

```dart
// Navigate to test page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StorageTestPage(),
  ),
);
```

---

## ✅ Pre-Flight Checklist

Before deploying:

- [ ] Storage Rules published in Firebase Console
- [ ] Tested upload on Android device
- [ ] Tested camera functionality
- [ ] Tested delete functionality
- [ ] Images display correctly
- [ ] Error handling works
- [ ] Loading states work

---

## 💻 Terminal Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean
flutter pub get
flutter run

# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

---

## 📁 Key Files

### Services
- `lib/services/storage_service.dart`

### Utils
- `lib/utils/image_picker_helper.dart`

### Widgets
- `lib/widgets/image_upload_widget.dart`

### Examples
- `lib/examples/recipe_form_with_image_example.dart`
- `lib/screens/storage_test_page.dart`

---

## 🎨 Color Codes (For UI)

```dart
// Success
Colors.green[700]

// Error
Colors.red[700]

// Loading
Colors.orange[700]

// Primary
AppTheme.primaryGreen
```

---

## 🔍 Debug Tips

```dart
// Enable debug prints
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Uploaded: $imageUrl');
  print('File size: ${file.lengthSync()} bytes');
}
```

---

## 📞 Where to Get Help

1. **Quick Start**: `STORAGE_QUICKSTART.md`
2. **Full Docs**: `README_STORAGE.md`
3. **Test Guide**: `QUICK_TEST_GUIDE.md`
4. **All Docs**: `00_DOCUMENTATION_INDEX.md`

---

## 🎉 Quick Win

Upload your first image in 5 minutes:

1. Set up Storage Rules → `FIREBASE_RULES_SETUP.md`
2. Add test button → `QUICK_TEST_GUIDE.md`
3. Run app and upload!
4. Check Firebase Console

---

**Print this card and keep it handy!** 📇

**Last Updated**: March 11, 2026
