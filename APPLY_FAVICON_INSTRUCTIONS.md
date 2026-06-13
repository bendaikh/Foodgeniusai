# 🎨 Apply Your Uploaded Favicon - Instructions

## ✅ Great! Your favicon is uploaded to Firebase Storage

Now you need to update `web/index.html` to use it.

---

## 📍 Step-by-Step Guide

### Step 1: Get Your Firebase URL

Your favicon was uploaded to Firebase Storage. The URL looks like:
```
https://firebasestorage.googleapis.com/v0/b/gourmetai-c432b.appspot.com/o/app_assets%2Ffavicon.png?alt=media&token=...
```

**How to get it:**
1. In the Admin Panel, after upload, click **"Copy URL"** button
2. Or click the **"How to Apply"** button (green outlined button)
3. Or go to Firebase Console → Storage → app_assets → favicon.png → Copy URL

---

### Step 2: Update web/index.html

**Open**: `web/index.html`

**Find line 52** (around line 51-52):
```html
<!-- Favicon -->
<link rel="icon" type="image/png" href="favicon.png"/>
```

**Replace with** (paste your Firebase URL):
```html
<!-- Favicon -->
<link rel="icon" type="image/png" href="YOUR_FIREBASE_STORAGE_URL_HERE"/>
```

**Example** (use your actual URL):
```html
<!-- Favicon -->
<link rel="icon" type="image/png" href="https://firebasestorage.googleapis.com/v0/b/gourmetai-c432b.appspot.com/o/app_assets%2Ffavicon.png?alt=media&token=abc123"/>
```

---

### Step 3: Rebuild the Web App

```bash
flutter build web --release
```

Wait for build to complete (~1-2 minutes).

---

### Step 4: Deploy to Firebase

```bash
firebase deploy --only hosting
```

Wait for deployment (~20-30 seconds).

---

### Step 5: Clear Browser Cache

1. **Hard refresh**: Press `Ctrl + F5`
2. **Or clear cache**: Press `Ctrl + Shift + Delete`
3. **Or use incognito**: Open in private/incognito mode

---

### Step 6: Verify

1. Visit your site: https://gourmetai-c432b.web.app
2. Look at the browser tab
3. ✅ Your custom favicon should appear!

---

## 🔄 Quick Commands

```bash
# Update web/index.html first, then:

# 1. Rebuild
flutter build web --release

# 2. Deploy
firebase deploy --only hosting

# 3. Hard refresh browser
# Ctrl + F5
```

---

## 💡 Tips

### Can't find your Firebase URL?
1. Go to Admin Panel → Settings → App Favicon
2. If favicon is uploaded, click **"How to Apply"** button
3. Copy the URL from there

### Favicon not updating?
- Clear browser cache (Ctrl + Shift + Delete)
- Try incognito/private mode
- Wait a few minutes for CDN cache to clear
- Verify the HTML was updated correctly

### Want to change favicon later?
1. Upload new favicon in Admin Panel
2. Copy new URL
3. Update `web/index.html` with new URL
4. Rebuild and deploy

---

## 📂 File Locations

**HTML File**: `web/index.html` (line 52)
**Firebase Storage**: `app_assets/favicon.png`
**Firestore**: `admin_settings/app_settings` (faviconUrl field)

---

## ✅ Checklist

- [ ] Favicon uploaded successfully ✅ (Done!)
- [ ] Copy Firebase Storage URL
- [ ] Update `web/index.html` line 52
- [ ] Run `flutter build web --release`
- [ ] Run `firebase deploy --only hosting`
- [ ] Clear browser cache / hard refresh
- [ ] Verify favicon appears in browser tab

---

**Status**: Favicon uploaded ✅  
**Next**: Update HTML → Rebuild → Deploy → Clear cache
