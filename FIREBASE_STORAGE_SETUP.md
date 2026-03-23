# Firebase Storage Setup Guide

## ✅ Setup Checklist

### 1. Firebase Console Configuration

#### A. Configure Storage Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **gourmetai**
3. Navigate to **Storage** in the left sidebar
4. Click on the **Rules** tab
5. Replace the default rules with the following:

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
    
    // Admin uploads (if needed later)
    match /admin/{allPaths=**} {
      allow read: if true;
      allow write: if false; // Manually configure admin access
    }
  }
}
```

6. Click **Publish** to save the rules

#### B. Enable CORS (Optional, for web)

If you're deploying to web, you might need to configure CORS. This is automatic for mobile apps.

### 2. Android Configuration

#### Add required permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Add these permissions inside <manifest> tag -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- Add this inside <application> tag -->
<application>
    ...
    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.fileprovider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
    </provider>
</application>
```

#### Create file provider paths at `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <cache-path name="cache" path="."/>
</paths>
```

### 3. iOS Configuration (if targeting iOS)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select recipe images</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take recipe photos</string>
```

## 📦 Package Overview

Your project now includes:

- ✅ `firebase_storage: ^11.5.6` - Firebase Storage SDK
- ✅ `image_picker: ^1.2.1` - Pick images from gallery/camera

## 🎨 Implementation Files

### 1. Storage Service (`lib/services/storage_service.dart`)
Handles all Firebase Storage operations:
- Upload images (recipes, profiles)
- Delete images
- List images
- Get metadata

### 2. Image Picker Helper (`lib/utils/image_picker_helper.dart`)
Utility for picking images:
- Pick from gallery
- Pick from camera
- Pick multiple images
- Show source selection dialog

### 3. Image Upload Widget (`lib/widgets/image_upload_widget.dart`)
Reusable widget for image upload UI:
- Drag & drop placeholder
- Upload progress indicator
- Image preview
- Edit/Delete buttons

## 🚀 Usage Examples

### Example 1: Simple Image Upload

```dart
import 'package:gourmetai/services/storage_service.dart';
import 'package:gourmetai/utils/image_picker_helper.dart';

// Pick and upload an image
final file = await ImagePickerHelper.pickImageFromGallery();
if (file != null) {
  final storageService = StorageService();
  final imageUrl = await storageService.uploadRecipeImage(
    file,
    userId: 'user123',
  );
  print('Image uploaded: $imageUrl');
}
```

### Example 2: Using ImageUploadWidget

```dart
import 'package:gourmetai/widgets/image_upload_widget.dart';

// In your widget build method:
ImageUploadWidget(
  userId: currentUserId,
  isRecipeImage: true,
  initialImageUrl: recipe?.imageUrl,
  onImageUploaded: (imageUrl) {
    setState(() {
      _recipeImageUrl = imageUrl;
    });
  },
  height: 250,
  width: double.infinity,
)
```

### Example 3: Delete an Image

```dart
final storageService = StorageService();
await storageService.deleteImageByUrl(recipe.imageUrl);
```

## 🔐 Security Rules Explained

- **Recipe Images** (`/recipes/{userId}/{fileName}`):
  - Anyone can read (public recipes)
  - Only authenticated users can upload their own images
  - Only owners can delete their images
  - Max file size: 5MB
  - Only image files allowed

- **Profile Pictures** (`/profiles/{userId}/{fileName}`):
  - Anyone can read
  - Only authenticated users can upload their own
  - Only owners can delete

## 📊 Firebase Storage Quotas (Blaze Plan - Free Tier)

- **Storage**: 5 GB total
- **Download**: 1 GB/day
- **Operations**: 50,000 downloads/day, 20,000 uploads/day

## 🧪 Testing

1. Run your app: `flutter run`
2. Navigate to recipe creation form
3. Add the ImageUploadWidget
4. Try uploading an image
5. Check Firebase Console → Storage to see uploaded files

## 🚨 Troubleshooting

### Images not uploading?
- Check Firebase console rules are published
- Check Android permissions are added
- Check internet connection
- Check Firebase is initialized (`main.dart`)

### Camera not working?
- Check camera permission in AndroidManifest.xml
- Test on a physical device (emulator camera is limited)

### File too large?
- Images are automatically compressed to 85% quality
- Max size set to 1920x1080 in ImagePickerHelper
- Storage rules enforce 5MB limit

## 📝 Next Steps

1. ✅ Add `ImageUploadWidget` to `recipe_form_page.dart`
2. ✅ Add `ImageUploadWidget` to admin recipe creation
3. ✅ Update Firestore recipes with `imageUrl` field
4. ✅ Display recipe images in recipe cards
5. ✅ Add placeholder images for recipes without photos

## 🎉 Done!

Your Firebase Storage is now ready to use. Upload and manage images in your GourmetAI app!
