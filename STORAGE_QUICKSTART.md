# 🎉 Firebase Storage - Quick Start Guide

## ✅ What's Been Done

Your Firebase Storage is now **fully configured** and ready to use! Here's what's set up:

### 1. **Dependencies Installed** ✅
- `firebase_storage: ^11.5.6` - Firebase Storage SDK
- `image_picker: ^1.2.1` - Image picker for gallery/camera

### 2. **Android Configuration** ✅
- Camera and storage permissions added to `AndroidManifest.xml`
- FileProvider configured for camera functionality
- File paths configured in `res/xml/file_paths.xml`

### 3. **Services Created** ✅
- **`storage_service.dart`** - Complete Firebase Storage service
- **`image_picker_helper.dart`** - Utility for picking images

### 4. **Widgets Created** ✅
- **`image_upload_widget.dart`** - Reusable image upload component
- **`storage_test_page.dart`** - Test page for storage functionality

### 5. **Examples Created** ✅
- **`recipe_form_with_image_example.dart`** - Shows how to integrate image upload

---

## 🚀 Next: Set Up Firebase Storage Rules

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **gourmetai**
3. Click **Storage** in the left sidebar
4. Click the **Rules** tab

### Step 2: Add These Security Rules

Replace the default rules with this:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isValidImage() {
      return request.resource.size < 5 * 1024 * 1024
          && request.resource.contentType.matches('image/.*');
    }
    
    match /recipes/{userId}/{fileName} {
      allow read: if true;
      allow write: if isAuthenticated() && isOwner(userId) && isValidImage();
      allow delete: if isAuthenticated() && isOwner(userId);
    }
    
    match /profiles/{userId}/{fileName} {
      allow read: if true;
      allow write: if isAuthenticated() && isOwner(userId) && isValidImage();
      allow delete: if isAuthenticated() && isOwner(userId);
    }
  }
}
```

### Step 3: Publish the Rules

Click the **Publish** button to save the rules.

---

## 🧪 Test Storage (Quick Test)

### Option 1: Add Test Button to Landing Page

Add this to your `landing_page.dart` temporarily:

```dart
import 'screens/storage_test_page.dart';

// Add this button somewhere in your build method:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StorageTestPage()),
    );
  },
  child: const Text('Test Storage'),
),
```

### Option 2: Test in Recipe Form

See the example file: `lib/examples/recipe_form_with_image_example.dart`

---

## 📱 How to Use in Your App

### Simple Upload Example

```dart
import 'package:gourmetai/services/storage_service.dart';
import 'package:gourmetai/utils/image_picker_helper.dart';

Future<void> uploadRecipeImage() async {
  // 1. Pick image
  final file = await ImagePickerHelper.pickImageFromGallery();
  if (file == null) return;
  
  // 2. Upload to Firebase Storage
  final storageService = StorageService();
  final imageUrl = await storageService.uploadRecipeImage(
    file,
    userId: 'current-user-id', // Replace with actual user ID
  );
  
  // 3. Save imageUrl to Firestore
  print('Uploaded: $imageUrl');
}
```

### Using the ImageUploadWidget

```dart
import 'package:gourmetai/widgets/image_upload_widget.dart';

// In your StatefulWidget:
String? _recipeImageUrl;

// In your build method:
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

## 📋 File Structure

```
lib/
├── services/
│   └── storage_service.dart          # Firebase Storage operations
├── utils/
│   └── image_picker_helper.dart      # Image picker utilities
├── widgets/
│   └── image_upload_widget.dart      # Reusable upload widget
├── screens/
│   └── storage_test_page.dart        # Test page
└── examples/
    └── recipe_form_with_image_example.dart  # Integration example
```

---

## 🎯 Integration Checklist

### For Recipe Creation:

- [ ] Set up Firebase Storage rules (see above)
- [ ] Add `ImageUploadWidget` to `recipe_form_page.dart`
- [ ] Store `imageUrl` in `RecipeModel` (already has the field!)
- [ ] Save recipe with image URL to Firestore
- [ ] Display images in recipe cards

### For User Profiles:

- [ ] Add profile picture upload in user settings
- [ ] Use `uploadProfilePicture()` method
- [ ] Store URL in user document

---

## 🔥 Storage Service API

### Upload Methods

```dart
// Upload recipe image (auto-organized by user)
await storageService.uploadRecipeImage(file, userId);

// Upload profile picture
await storageService.uploadProfilePicture(file, userId);

// Upload to custom path
await storageService.uploadImage(file, 'custom/path/image.jpg');
```

### Delete Methods

```dart
// Delete by URL
await storageService.deleteImageByUrl(imageUrl);

// Delete by path
await storageService.deleteImageByPath('recipes/user123/image.jpg');
```

### List Methods

```dart
// List all images in directory
final urls = await storageService.listImages('recipes/user123/');
```

---

## 📊 Storage Limits (Blaze Free Tier)

- **Storage**: 5 GB
- **Download**: 1 GB/day
- **Uploads**: 20,000/day
- **Downloads**: 50,000/day

---

## 🚨 Common Issues

### "Permission Denied" Error
- Make sure you published the Storage rules in Firebase Console
- Check that user is authenticated
- Verify user ID matches the path

### Camera Not Working
- Test on a real device (emulator camera is limited)
- Check permissions in `AndroidManifest.xml`

### Image Not Uploading
- Check internet connection
- Verify Firebase is initialized in `main.dart`
- Check file size (5MB limit)

---

## 🎉 You're All Set!

1. ✅ **Set up Storage Rules** in Firebase Console (see Step 1-3 above)
2. ✅ **Test the upload** using `StorageTestPage`
3. ✅ **Integrate into your app** using the examples provided

For detailed setup instructions, see: **`FIREBASE_STORAGE_SETUP.md`**

---

## 📝 Next Steps

1. Add image upload to recipe creation form
2. Display recipe images in recipe cards
3. Add profile picture upload
4. Add placeholder images for recipes without photos

**Happy coding!** 🚀
