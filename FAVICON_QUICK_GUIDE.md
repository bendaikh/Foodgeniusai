# 🎨 Upload Custom Favicon - Quick Guide

## ✅ Feature Ready!

You can now upload a custom favicon to replace the Flutter default!

---

## 🚀 Steps to Upload

### 1. Go to Admin Settings
```
https://gourmetai-c432b.web.app/#/admin
→ Settings → Application Settings → App Favicon
```

### 2. Select & Upload
1. Click **"Select Favicon"**
2. Choose your image (PNG, ICO, or JPEG)
3. Preview appears
4. Click **"Upload"**
5. Click **"Copy URL"** from success message

### 3. Update HTML
Edit `web/index.html`:
```html
<link rel="icon" type="image/png" href="YOUR_FIREBASE_URL"/>
```

### 4. Rebuild & Deploy
```bash
flutter build web --release
firebase deploy --only hosting
```

### 5. Clear Cache
- Ctrl + Shift + Delete
- Hard refresh (Ctrl + F5)
- ✅ Done!

---

## 💡 Tips

**Best sizes**: 32x32, 192x192, or 512x512 pixels
**Best format**: PNG with transparent background
**Storage**: Automatically saved to Firebase Storage

---

## 📍 Where to Find It

Admin Panel → Settings (sidebar) → Scroll to "Application Settings" → "App Favicon" section

---

**Status**: ✅ Deployed and ready to use!
