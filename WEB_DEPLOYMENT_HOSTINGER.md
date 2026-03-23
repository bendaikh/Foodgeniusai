# 🌐 GourmetAI Web Deployment Guide (Hostinger)

## Complete Step-by-Step Instructions for Deploying to Your Domain

---

## 📋 What You'll Need

- [ ] Hostinger hosting account (you have this)
- [ ] Domain name configured
- [ ] Flutter SDK installed on your computer
- [ ] Firebase project configured
- [ ] OpenAI API key configured
- [ ] 1-2 hours of time

---

## Part 1: Build Your Web App

### Step 1: Prepare Your Environment

Open PowerShell in your project folder:

```powershell
cd C:\Users\Espacegamers\Documents\gourmetai
```

### Step 2: Clean Previous Builds

```powershell
flutter clean
```

This removes old build artifacts.

### Step 3: Get Dependencies

```powershell
flutter pub get
```

This downloads all required packages.

### Step 4: Build for Production

```powershell
flutter build web --release
```

**What this does:**
- Compiles your Flutter app to optimized JavaScript
- Minifies code for faster loading
- Creates production-ready files
- Outputs to `build\web\` folder

**Wait for completion** - This takes 2-5 minutes.

### Step 5: Verify Build Success

Check that these files exist:
- `build\web\index.html`
- `build\web\flutter.js`
- `build\web\main.dart.js`
- `build\web\assets\` folder

### 🎯 Quick Build Script

Or simply run:
```powershell
.\deploy-web.ps1
```

This automated script:
- Cleans previous builds
- Gets dependencies
- Builds web app
- Opens build folder automatically

---

## Part 2: Configure Firebase for Your Domain

**Before uploading**, you must add your domain to Firebase.

### Step 1: Open Firebase Console

1. Go to: https://console.firebase.google.com/
2. Sign in with your Google account
3. Select your GourmetAI project

### Step 2: Add Authorized Domain

1. Click "Authentication" in left sidebar
2. Click "Settings" tab at top
3. Scroll to "Authorized domains" section
4. Click "Add domain"

### Step 3: Add Your Domains

Add BOTH of these:
- `yourdomain.com` (replace with your actual domain)
- `www.yourdomain.com`

**Example:** If your domain is `gourmetai-app.com`:
- Add: `gourmetai-app.com`
- Add: `www.gourmetai-app.com`

Click "Add" for each.

### Why This is Important

Without this step:
- Firebase authentication won't work
- Users can't log in
- App will show errors

---

## Part 3: Upload to Hostinger

### Method A: File Manager (Easiest for Beginners)

#### Step 1: Login to Hostinger

1. Go to: https://www.hostinger.com/
2. Click "Login" (top right)
3. Enter your email and password
4. Click "Hosting" in dashboard

#### Step 2: Access File Manager

1. Find your hosting plan
2. Click "Manage"
3. Look for "File Manager" button
4. Click "File Manager" - Opens in new tab

#### Step 3: Navigate to public_html

1. In File Manager, you'll see folders
2. Double-click `public_html` folder
3. This is your website's root directory
4. Everything here is publicly accessible

#### Step 4: Backup Existing Files (Optional)

If you have existing files:
1. Create new folder: `backup_old_site`
2. Select all existing files
3. Move to backup folder
4. Or delete if not needed

#### Step 5: Upload Your App Files

1. Click "Upload Files" button (usually top right)
2. Navigate to your project folder:
   ```
   C:\Users\Espacegamers\Documents\gourmetai\build\web\
   ```
3. **Select ALL files and folders:**
   - `index.html`
   - `flutter.js`
   - `main.dart.js`
   - `flutter_service_worker.js`
   - `manifest.json`
   - `version.json`
   - `assets` folder (entire folder)
   - `canvaskit` folder (entire folder)
   - Any other files/folders
   
4. Click "Upload" or drag and drop
5. **Wait for upload to complete** - May take 5-10 minutes
6. Verify all files uploaded successfully

#### Step 6: Upload .htaccess File

**CRITICAL**: This file enables Flutter routing.

1. In File Manager, ensure you're in `public_html`
2. Click "Upload Files"
3. Navigate to:
   ```
   C:\Users\Espacegamers\Documents\gourmetai\.htaccess
   ```
4. Upload this file
5. Refresh File Manager
6. Verify `.htaccess` appears in file list

**If .htaccess not visible:**
- Click Settings/Preferences in File Manager
- Enable "Show hidden files"
- Refresh page

---

### Method B: FTP Upload (Professional Method)

#### Step 1: Get FTP Credentials

1. Login to Hostinger
2. Go to your hosting dashboard
3. Find "FTP Accounts" section
4. Note down:
   - **Hostname**: usually `ftp.yourdomain.com` or IP address
   - **Username**: usually your hosting username
   - **Password**: your FTP password
   - **Port**: usually `21`

If you don't have FTP account:
- Click "Create FTP Account"
- Follow prompts
- Save credentials securely

#### Step 2: Download FileZilla

1. Go to: https://filezilla-project.org/
2. Download FileZilla Client (free)
3. Install on your computer
4. Open FileZilla

#### Step 3: Connect to Your Server

1. In FileZilla, enter at top:
   - **Host**: `ftp.yourdomain.com` (or the hostname from Hostinger)
   - **Username**: Your FTP username
   - **Password**: Your FTP password
   - **Port**: `21`
2. Click "Quickconnect"
3. Accept any security certificates
4. Wait for connection

**Connection Success:**
- Left side: Your computer
- Right side: Your server

#### Step 4: Navigate to public_html

1. On **right side** (server):
   - Double-click folders to navigate
   - Find and open `public_html` folder
2. On **left side** (computer):
   - Navigate to: `C:\Users\Espacegamers\Documents\gourmetai\build\web\`

#### Step 5: Upload Files

1. On **left side**, select ALL files in `web` folder:
   - Hold Ctrl+A to select all
2. Right-click selection
3. Click "Upload"
4. Watch transfer queue at bottom
5. **Wait for all files to upload** - 5-10 minutes
6. Verify file count matches on both sides

#### Step 6: Upload .htaccess

1. Navigate left side to: `C:\Users\Espacegamers\Documents\gourmetai\`
2. Find `.htaccess` file
3. Drag to right side `public_html` folder
4. Confirm upload

#### Step 7: Set Permissions (If Needed)

1. On right side, right-click `.htaccess`
2. Click "File permissions"
3. Set to: `644` (usually default)
4. Click OK

---

## Part 4: Configure SSL Certificate (HTTPS)

### Why SSL is Important
- Secures data transmission
- Required for Firebase auth
- Improves SEO ranking
- Shows "secure" in browser

### Step 1: Access SSL Settings

1. Login to Hostinger
2. Go to hosting dashboard
3. Find "SSL" section

### Step 2: Enable SSL

1. Click "Manage" next to your domain
2. Look for SSL options
3. Enable "Free SSL" (Let's Encrypt)
4. Click "Install SSL" or "Enable"

### Step 3: Wait for Activation

- **Time**: 10-30 minutes
- **Status**: Check SSL section for progress
- **When complete**: Certificate icon shows "Active"

### Step 4: Force HTTPS

Add this to your `.htaccess` file (should already be there):

```apache
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

This redirects all HTTP traffic to HTTPS.

### Step 5: Test SSL

1. Visit: `https://yourdomain.com`
2. Check for padlock icon in browser
3. Click padlock → Certificate should be valid

---

## Part 5: Upload Privacy Policy & Terms

### Step 1: Upload Privacy Policy

1. In File Manager, go to `public_html`
2. Upload `privacy-policy.html` from your project
3. Verify file uploaded

Test: Visit `https://yourdomain.com/privacy-policy.html`

### Step 2: Upload Terms of Service

1. In File Manager, go to `public_html`
2. Upload `terms-of-service.html`
3. Verify file uploaded

Test: Visit `https://yourdomain.com/terms-of-service.html`

### Step 3: Update Policy URLs

Update these files with your actual domain:
- `privacy-policy.html` - Replace `yourdomain.com` with your domain
- `terms-of-service.html` - Replace `yourdomain.com` with your domain
- Replace email addresses: `support@yourdomain.com` with your email

---

## Part 6: Test Your Deployment

### Essential Tests

#### 1. Homepage Loads
- Visit: `https://yourdomain.com`
- Should show GourmetAI landing page
- No errors in browser console (F12)

#### 2. User Registration
- Click "Sign Up" or register button
- Enter email and password
- Should create account successfully
- Check Firebase Console → Authentication → Users

#### 3. User Login
- Enter registered email and password
- Click "Login"
- Should log in successfully
- Should see user dashboard

#### 4. Recipe Generation
- Try generating a recipe
- Enter some ingredients
- Click generate
- Should return AI-generated recipe
- Verify OpenAI API is working

#### 5. Admin Access
- Visit: `https://yourdomain.com/admin`
- Should show admin login page
- Login with admin credentials
- Should access admin dashboard

#### 6. Routing Works
- Navigate between pages
- Click back/forward in browser
- URLs should update correctly
- Pages should load without errors

#### 7. Mobile Responsive
- Open on phone/tablet
- Check all features work
- Verify layout looks good

### Browser Console Check

1. Press F12 to open DevTools
2. Click "Console" tab
3. Look for errors (red text)
4. Common issues:
   - 404 errors = files not uploaded correctly
   - CORS errors = Firebase config issue
   - API errors = Check Firebase/OpenAI keys

### Network Tab Check

1. Press F12 → Network tab
2. Reload page (Ctrl+F5)
3. Check all files load:
   - Status: 200 (green)
   - No 404 errors (red)
4. Check load times:
   - Initial load: < 3 seconds ideal
   - Subsequent: < 1 second

---

## Part 7: Performance Optimization

### Enable Compression

Your `.htaccess` file already includes compression rules.

Verify compression is working:
1. Go to: https://www.giftofspeed.com/gzip-test/
2. Enter your domain
3. Should show "GZIP is enabled"

### Enable Caching

Already configured in `.htaccess` file.

Test caching:
1. Visit your site
2. Reload page (F5)
3. Files should load from cache (faster)

### CDN (Optional - Advanced)

For faster global loading:
1. Consider Cloudflare (free tier available)
2. Or Hostinger CDN if included in plan
3. Can add later as you grow

---

## Part 8: Domain Configuration

### Verify DNS Settings

Your domain should point to Hostinger's servers.

#### Check DNS:
1. Hostinger Dashboard → Domains
2. Click your domain
3. Go to DNS settings
4. Should see A records pointing to Hostinger IPs

#### Typical DNS Records:
```
Type: A
Name: @
Value: [Hostinger IP address]
TTL: 14400

Type: A  
Name: www
Value: [Hostinger IP address]
TTL: 14400
```

### WWW vs Non-WWW

Decide which you prefer:
- `gourmetai.com` (non-www)
- `www.gourmetai.com` (www)

Both should work, but set one as primary.

In Hostinger:
1. Go to domain settings
2. Set preferred domain
3. Enable redirect from other version

---

## Part 9: Post-Deployment Checklist

After deployment, verify:

### Functionality
- [ ] Homepage loads correctly
- [ ] User registration works
- [ ] User login works  
- [ ] Recipe generation works
- [ ] Admin panel accessible
- [ ] All pages load correctly
- [ ] Images display properly
- [ ] No console errors

### Configuration
- [ ] SSL certificate active (HTTPS)
- [ ] Firebase authorized domains added
- [ ] Privacy policy accessible
- [ ] Terms of service accessible
- [ ] .htaccess file uploaded
- [ ] All files uploaded correctly

### Performance
- [ ] Page loads in < 3 seconds
- [ ] GZIP compression enabled
- [ ] Caching enabled
- [ ] Mobile responsive
- [ ] Works on all major browsers

### Security
- [ ] HTTPS enabled
- [ ] Firebase rules configured
- [ ] API keys secured
- [ ] Admin password strong

---

## Troubleshooting

### Problem: White Screen / Blank Page

**Causes:**
- Files not uploaded correctly
- Missing files
- JavaScript errors

**Solutions:**
1. Check browser console (F12)
2. Verify ALL files uploaded
3. Check file permissions (644 for files, 755 for folders)
4. Clear browser cache (Ctrl+Shift+Del)
5. Rebuild app: `flutter build web --release`

---

### Problem: "Failed to load Firebase"

**Causes:**
- Domain not in Firebase authorized domains
- Wrong Firebase config

**Solutions:**
1. Add domain to Firebase Console → Authentication → Authorized domains
2. Verify `firebase_options.dart` has correct config
3. Wait 5-10 minutes for Firebase to update
4. Clear browser cache

---

### Problem: Login/Registration Not Working

**Causes:**
- Domain not authorized in Firebase
- HTTPS not enabled
- Firebase config incorrect

**Solutions:**
1. Verify SSL is active (HTTPS)
2. Add domain to Firebase authorized domains
3. Check Firebase Console → Authentication is enabled
4. Test with incognito/private window

---

### Problem: 404 Error on Page Refresh

**Causes:**
- .htaccess not uploaded or not working
- Hostinger doesn't support .htaccess

**Solutions:**
1. Verify .htaccess file uploaded to public_html
2. Check file is named exactly `.htaccess` (with dot)
3. Enable "Show hidden files" in File Manager
4. Contact Hostinger support to enable mod_rewrite

---

### Problem: Slow Loading Times

**Solutions:**
1. Enable compression (already in .htaccess)
2. Enable caching (already in .htaccess)
3. Optimize images
4. Consider CDN
5. Check Hostinger server location vs. your users

---

### Problem: Can't Access Admin Panel

**Solutions:**
1. Visit: `https://yourdomain.com/admin` (not /admin/)
2. Verify .htaccess routing rules
3. Check admin account exists in Firebase
4. Try creating new admin account
5. Check browser console for errors

---

## Updating Your Web App

### For Future Updates

1. Make code changes locally
2. Test changes: `flutter run -d chrome`
3. Build new version: `flutter build web --release`
4. Upload new files to Hostinger (overwrite existing)
5. Clear browser cache to test
6. Verify all features still work

### Quick Update Script

```powershell
.\deploy-web.ps1
```

Then upload the new `build\web\` contents.

---

## Monitoring Your Website

### Hostinger Analytics

1. Login to Hostinger
2. Go to hosting dashboard
3. Click "Analytics" or "Statistics"
4. View:
   - Visitor counts
   - Bandwidth usage
   - Page views
   - Geographic data

### Google Analytics (Optional)

1. Create Google Analytics account
2. Get tracking ID
3. Add to your Flutter web app
4. Track detailed user behavior

### Firebase Analytics

Already integrated in your app:
1. Firebase Console → Analytics
2. View:
   - Active users
   - User engagement
   - Feature usage

---

## Security Best Practices

### Regular Updates
- Update Flutter SDK regularly
- Update dependencies: `flutter pub upgrade`
- Monitor Firebase for security updates
- Keep hosting platform updated

### Backups
- Backup your code (Git)
- Download website files periodically
- Export Firebase data monthly
- Keep local copies secure

### Monitoring
- Check Hostinger for security alerts
- Monitor Firebase Console for unusual activity
- Review user registrations regularly
- Watch for spam or abuse

---

## Cost Management

### Hostinger Costs
- Hosting plan: ~$2-10/month (depending on plan)
- Domain renewal: ~$10-15/year
- SSL: Free (Let's Encrypt)

### Firebase Costs
- Free tier: Usually sufficient for starting
- Monitor usage: Firebase Console → Usage
- Set budget alerts
- Typical costs: $0-50/month depending on users

### OpenAI Costs
- Pay-as-you-go pricing
- Monitor usage in OpenAI dashboard
- Set usage limits
- Typical costs: $10-100/month depending on recipe generations

---

## Getting Help

### Hostinger Support
- **Live Chat**: Available 24/7 in dashboard
- **Tutorials**: https://www.hostinger.com/tutorials
- **Knowledge Base**: Extensive help articles

### Flutter/Firebase Support
- **Flutter Docs**: https://docs.flutter.dev/
- **Firebase Docs**: https://firebase.google.com/docs
- **Community**: Stack Overflow, Reddit

### Emergency Contacts
- Hostinger Support: Via dashboard live chat
- Firebase Support: Via Firebase Console
- Domain Issues: Check registrar support

---

## Success! 🎉

Your GourmetAI web app is now live!

**Next Steps:**
1. Share your URL with friends for testing
2. Collect feedback
3. Make improvements
4. Plan Android/iOS deployment
5. Market your app

**Your URLs:**
- Website: `https://yourdomain.com`
- Admin: `https://yourdomain.com/admin`
- Privacy: `https://yourdomain.com/privacy-policy.html`
- Terms: `https://yourdomain.com/terms-of-service.html`

---

## Quick Reference Commands

```powershell
# Build web app
flutter build web --release

# Or use automated script
.\deploy-web.ps1

# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release

# Test locally
flutter run -d chrome
```

---

## Files to Upload to public_html

```
build/web/
├── index.html
├── flutter.js
├── main.dart.js
├── flutter_service_worker.js
├── manifest.json
├── version.json
├── assets/
│   └── [all asset files]
├── canvaskit/
│   └── [all canvaskit files]
└── [any other generated files]

Plus separately:
├── .htaccess (from project root)
├── privacy-policy.html (from project root)
└── terms-of-service.html (from project root)
```

---

Congratulations on deploying your web app! 🚀🌐
