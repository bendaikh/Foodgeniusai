# ✅ Firebase Storage Setup Checklist

Print this and check off items as you complete them!

---

## Phase 1: Initial Setup (REQUIRED)

### Firebase Console Setup
- [ ] Open Firebase Console: https://console.firebase.google.com/
- [ ] Select project: **gourmetai**
- [ ] Go to **Storage** section
- [ ] Click **Rules** tab
- [ ] Copy rules from `FIREBASE_RULES_SETUP.md`
- [ ] Paste rules into editor
- [ ] Click **Publish** button
- [ ] Verify "Rules successfully published" message appears

**⚠️ Cannot proceed until this is done!**

---

## Phase 2: Test Storage (REQUIRED)

### Add Test Button
- [ ] Open `lib/screens/landing_page.dart`
- [ ] Add import: `import 'storage_test_page.dart';`
- [ ] Add test button (see `QUICK_TEST_GUIDE.md`)
- [ ] Save file

### Run Test
- [ ] Run command: `flutter run`
- [ ] Click "Test Storage" button
- [ ] Click "Upload Test Image"
- [ ] Choose Gallery or Camera
- [ ] Select/take a photo
- [ ] Wait for upload
- [ ] See "✅ Image uploaded successfully!" message
- [ ] Image appears in app list

### Verify in Firebase
- [ ] Open Firebase Console
- [ ] Go to Storage → Files
- [ ] See uploaded image in `recipes/test-user-{timestamp}/`
- [ ] Click on image to view
- [ ] Verify download URL works

### Test Delete
- [ ] Click delete button on uploaded image
- [ ] See "✅ Image deleted!" message
- [ ] Check Firebase Console
- [ ] Verify image is removed

**✅ If all tests pass, storage is working!**

---

## Phase 3: Integration (RECOMMENDED)

### Recipe Form Integration
- [ ] Open `lib/screens/recipe_form_page.dart`
- [ ] Read example: `lib/examples/recipe_form_with_image_example.dart`
- [ ] Add `String? _recipeImageUrl;` to state
- [ ] Add `ImageUploadWidget` to form
- [ ] Connect `onImageUploaded` callback
- [ ] Test recipe creation with image

### Firestore Integration
- [ ] Verify `RecipeModel` has `imageUrl` field ✅ (already exists)
- [ ] Update recipe creation to include `imageUrl`
- [ ] Save recipe to Firestore
- [ ] Verify `imageUrl` appears in Firestore document

### Display Images
- [ ] Update recipe cards to show images
- [ ] Add `Image.network(recipe.imageUrl)` where needed
- [ ] Add loading placeholder
- [ ] Add error placeholder
- [ ] Add fallback icon for recipes without images

---

## Phase 4: UI Polish (OPTIONAL)

### Error Handling
- [ ] Test with no internet (airplane mode)
- [ ] Verify error messages appear
- [ ] Test with large image (>5MB)
- [ ] Verify size limit error appears

### Loading States
- [ ] Verify upload progress shows
- [ ] Verify loading spinner during upload
- [ ] Verify image preview works

### User Experience
- [ ] Test camera on real device
- [ ] Test gallery picker
- [ ] Test edit/replace image
- [ ] Test delete image
- [ ] Verify all success/error messages are user-friendly

---

## Phase 5: Profile Pictures (OPTIONAL)

### Profile Upload
- [ ] Add profile picture upload to user settings
- [ ] Use `uploadProfilePicture()` method
- [ ] Save URL to user document in Firestore
- [ ] Display profile picture in app

---

## Phase 6: Cleanup

### Remove Test Code
- [ ] Remove "Test Storage" button from landing page
- [ ] Remove test imports
- [ ] Clean up any console.log statements
- [ ] Remove unused example files (optional)

---

## Phase 7: Monitoring (ONGOING)

### Firebase Console
- [ ] Check storage usage regularly
- [ ] Monitor download bandwidth
- [ ] Check for unusual activity
- [ ] Verify rules are working correctly

### App Performance
- [ ] Test app with slow internet
- [ ] Test with many images
- [ ] Monitor memory usage
- [ ] Check image load times

---

## 📋 Quick Reference

### Commands
```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean && flutter pub get && flutter run
```

### Key Files
- Rules: `FIREBASE_RULES_SETUP.md`
- Quick Start: `STORAGE_QUICKSTART.md`
- Testing: `QUICK_TEST_GUIDE.md`
- Examples: `lib/examples/recipe_form_with_image_example.dart`

### Firebase Console
- URL: https://console.firebase.google.com/
- Project: **gourmetai**
- Storage: https://console.firebase.google.com/project/gourmetai/storage

---

## ✅ Final Verification

Before going live, verify:

- [ ] ✅ Storage rules are published
- [ ] ✅ Upload works on Android device
- [ ] ✅ Camera works on real device
- [ ] ✅ Gallery picker works
- [ ] ✅ Images appear in Firebase Console
- [ ] ✅ Images display in app
- [ ] ✅ Delete works
- [ ] ✅ Error handling works
- [ ] ✅ No console errors
- [ ] ✅ No memory leaks

---

## 🎉 Status

Current Status: ⬜ Not Started / ⏳ In Progress / ✅ Complete

- Phase 1 (Setup): ⬜
- Phase 2 (Test): ⬜
- Phase 3 (Integration): ⬜
- Phase 4 (Polish): ⬜
- Phase 5 (Profiles): ⬜
- Phase 6 (Cleanup): ⬜
- Phase 7 (Monitoring): ⬜

---

**Mark this checklist as you go! Good luck!** 🚀
