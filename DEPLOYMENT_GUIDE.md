# 🚀 GourmetAI Complete Deployment Guide

## Overview
This guide will help you deploy your GourmetAI app on:
1. **Web** - Hosted on your Hostinger domain
2. **Android** - Published on Google Play Store
3. **iOS** - Published on Apple App Store

---

## 📋 Pre-Deployment Checklist

### Required Accounts
- [ ] Hostinger account (you have this)
- [ ] Google Play Console account ($25 one-time fee)
- [ ] Apple Developer account ($99/year)
- [ ] Firebase project configured
- [ ] OpenAI API key configured

### Required Software
- [ ] Flutter SDK installed
- [ ] Node.js installed (for Firebase)
- [ ] Firebase CLI installed
- [ ] Android Studio (for Android)
- [ ] Xcode (for iOS, macOS only)

---

## 🌐 PART 1: Web Deployment (Hostinger)

### Step 1: Build Your Web App

Open PowerShell in your project directory and run:

```powershell
# Build the web app for production
flutter build web --release

# This creates files in: build/web/
```

### Step 2: Prepare Web Files

Your web app is now in `build/web/` folder. This contains:
- `index.html`
- `main.dart.js`
- `flutter.js`
- `assets/` folder
- Other necessary files

### Step 3: Deploy to Hostinger

#### Option A: Using Hostinger File Manager (Easiest)

1. **Login to Hostinger**
   - Go to https://www.hostinger.com/
   - Login to your account
   - Go to "Hosting" → Select your hosting plan

2. **Access File Manager**
   - Click "File Manager" in your hosting control panel
   - Navigate to `public_html` folder (this is your website root)

3. **Upload Files**
   - Delete any existing files in `public_html` (or move to backup folder)
   - Upload ALL files from `build/web/` to `public_html/`
   - Make sure `index.html` is in the root of `public_html/`

4. **Configure for Flutter Web**
   - Create/Edit `.htaccess` file in `public_html/`:

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  
  # Don't rewrite files or directories
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  
  # Rewrite everything else to index.html for Flutter routing
  RewriteRule ^.*$ /index.html [L]
</IfModule>

# Enable CORS for Firebase
<IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "*"
  Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
  Header set Access-Control-Allow-Headers "Content-Type"
</IfModule>

# Cache control for better performance
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/gif "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
  ExpiresByType application/x-javascript "access plus 1 month"
  ExpiresByType text/javascript "access plus 1 month"
</IfModule>
```

#### Option B: Using FTP (Professional Method)

1. **Get FTP Credentials from Hostinger**
   - Go to your Hostinger control panel
   - Find "FTP Accounts"
   - Note: hostname, username, password, port (usually 21)

2. **Install FileZilla** (FTP Client)
   - Download from: https://filezilla-project.org/

3. **Connect via FTP**
   - Open FileZilla
   - Enter: Host, Username, Password, Port
   - Click "Quickconnect"

4. **Upload Files**
   - Navigate to `public_html` on remote (right side)
   - Navigate to `build/web/` on local (left side)
   - Select all files and drag to upload

### Step 4: Configure Firebase for Your Domain

1. **Update Firebase Authorized Domains**
   - Go to Firebase Console: https://console.firebase.google.com/
   - Select your GourmetAI project
   - Go to "Authentication" → "Settings" → "Authorized domains"
   - Add your domain: `yourdomain.com` and `www.yourdomain.com`
   - Click "Add domain"

2. **Test Your Web App**
   - Visit: `https://yourdomain.com`
   - Test login functionality
   - Test admin panel: `https://yourdomain.com/admin`
   - Test all features

### Step 5: Setup SSL Certificate (HTTPS)

Hostinger usually provides free SSL:
1. Go to Hostinger control panel
2. Find "SSL" section
3. Enable SSL for your domain
4. Wait 10-15 minutes for activation
5. Your site will be accessible via https://

---

## 🤖 PART 2: Android Deployment (Google Play Store)

### Step 1: Prepare Your App for Release

#### A. Create a Keystore (Signing Key)

Run this in PowerShell:

```powershell
# Navigate to your project
cd C:\Users\Espacegamers\Documents\gourmetai

# Create android directory if needed
cd android

# Generate keystore
keytool -genkey -v -keystore gourmetai-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gourmetai

# Follow prompts and remember:
# - Keystore password
# - Key alias password
# - Your name/organization details
```

**IMPORTANT**: Save this keystore file and passwords securely! You'll need them for all future updates.

#### B. Configure App Signing

Create file: `android/key.properties`

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gourmetai
storeFile=gourmetai-release-key.jks
```

#### C. Update build.gradle

Edit: `android/app/build.gradle`

Find the `android` block and add:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### D. Update App Information

Edit: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.gourmetai.app">
    
    <application
        android:label="GourmetAI"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add this for internet permission -->
        <uses-permission android:name="android.permission.INTERNET"/>
        <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
        
        ...
    </application>
</manifest>
```

### Step 2: Build Android Release APK/AAB

```powershell
# Clean previous builds
flutter clean
flutter pub get

# Build App Bundle (AAB) - Required for Play Store
flutter build appbundle --release

# Output will be at: build/app/outputs/bundle/release/app-release.aab

# Optional: Build APK for testing
flutter build apk --release

# Output will be at: build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Create Google Play Developer Account

1. **Sign up for Google Play Console**
   - Go to: https://play.google.com/console
   - Pay $25 one-time registration fee
   - Fill in developer profile

2. **Create New App**
   - Click "Create app"
   - App name: "GourmetAI"
   - Default language: English
   - App/Game: App
   - Free/Paid: Choose your model
   - Accept declarations
   - Click "Create app"

### Step 4: Prepare Store Listing

You'll need to provide:

#### App Information
- **App name**: GourmetAI
- **Short description** (80 chars max):
  ```
  AI-powered recipe generator and kitchen management tool
  ```
  
- **Full description** (4000 chars max):
  ```
  GourmetAI - Your Personal AI Chef

  Transform your cooking experience with AI-powered recipe generation!

  🍳 KEY FEATURES:
  • AI Recipe Generation - Get personalized recipes based on ingredients you have
  • Smart Ingredient Management - Track your kitchen inventory
  • Step-by-step Cooking Instructions
  • Save Your Favorite Recipes
  • Share Recipes with Friends
  • Dietary Preference Support
  • Nutrition Information

  🎯 PERFECT FOR:
  • Home cooks looking for inspiration
  • People wanting to reduce food waste
  • Anyone learning to cook
  • Meal planning enthusiasts

  🔒 SECURE & PRIVATE:
  • Firebase authentication
  • Your data is always secure
  • No ads, no tracking

  Download GourmetAI now and start your culinary journey!
  ```

#### Graphics Assets Needed
You need to create these images:

1. **App Icon** (512x512px)
2. **Feature Graphic** (1024x500px)
3. **Screenshots** (minimum 2):
   - Phone: 1080x1920px or 1080x2340px
   - Tablet (optional): 2048x1536px

4. **Short promotional video** (optional but recommended)

### Step 5: Upload App Bundle

1. **Go to "Production" → "Create new release"**
2. **Upload the AAB file**: `build/app/outputs/bundle/release/app-release.aab`
3. **Fill in release details**:
   - Release name: "1.0.0"
   - Release notes:
     ```
     Initial release of GourmetAI
     - AI-powered recipe generation
     - User authentication
     - Recipe management
     - Admin panel
     ```

### Step 6: Complete Content Rating

1. Go to "Content rating"
2. Answer questionnaire honestly
3. Most recipe apps get "Everyone" rating

### Step 7: Set Pricing & Distribution

1. Select countries (or worldwide)
2. Set price (Free or Paid)
3. Confirm compliance with policies

### Step 8: Submit for Review

1. Complete all required sections (marked with red !)
2. Click "Send for review"
3. Wait 3-7 days for approval
4. You'll receive email notification

---

## 🍎 PART 3: iOS Deployment (Apple App Store)

**NOTE**: iOS deployment requires a Mac computer with Xcode. If you don't have a Mac, you'll need to use a cloud Mac service or skip iOS deployment for now.

### Step 1: Requirements

- Mac computer with macOS
- Xcode installed (latest version)
- Apple Developer account ($99/year)
- Valid Apple ID

### Step 2: Enroll in Apple Developer Program

1. Go to: https://developer.apple.com/programs/
2. Sign up with your Apple ID
3. Pay $99 annual fee
4. Complete enrollment (may take 24-48 hours)

### Step 3: Configure App in Xcode

**On your Mac:**

```bash
# Open iOS project in Xcode
cd ~/path/to/gourmetai
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Runner" in project navigator
2. Go to "Signing & Capabilities"
3. Select your team
4. Update Bundle Identifier: `com.gourmetai.app`
5. Enable "Automatically manage signing"

### Step 4: Update iOS Configuration

Edit: `ios/Runner/Info.plist`

Add necessary permissions:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload recipe images</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take recipe photos</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We use location to find nearby ingredients</string>
```

### Step 5: Build iOS Release

```bash
# Clean and build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Or build IPA
flutter build ipa --release
```

### Step 6: Create App in App Store Connect

1. **Go to App Store Connect**
   - Visit: https://appstoreconnect.apple.com/
   - Sign in with Apple Developer account

2. **Create New App**
   - Click "My Apps" → "+" → "New App"
   - Platform: iOS
   - Name: GourmetAI
   - Primary Language: English
   - Bundle ID: com.gourmetai.app
   - SKU: gourmetai-ios-001
   - User Access: Full Access

### Step 7: Prepare App Store Listing

#### App Information
- **Name**: GourmetAI
- **Subtitle** (30 chars): AI Chef in Your Pocket
- **Category**: Food & Drink
- **Secondary Category**: Lifestyle

#### Privacy Policy
You need a privacy policy URL. Create a simple one:
- Host it on your website: `https://yourdomain.com/privacy-policy.html`

#### Description
Similar to Android, but formatted for Apple:
```
Transform your cooking experience with AI-powered recipes!

KEY FEATURES:
• AI Recipe Generation
• Smart Ingredient Tracking
• Step-by-step Instructions
• Save & Share Recipes
• Dietary Preferences
• Nutrition Information

Perfect for home cooks, beginners, and food enthusiasts.

Download GourmetAI and unleash your inner chef!
```

#### Screenshots Required
- 6.5" iPhone: 1242x2688px (minimum 3 screenshots)
- 5.5" iPhone: 1242x2208px
- iPad Pro: 2048x2732px (if supporting iPad)

#### App Preview Video (Optional)
- 30-second demo video
- Shows key features

### Step 8: Upload Build

**Using Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device" as target
3. Product → Archive
4. Wait for archive to complete
5. Click "Distribute App"
6. Select "App Store Connect"
7. Upload

**Or using Command Line:**
```bash
# After building IPA
cd build/ios/ipa
xcrun altool --upload-app -f GourmetAI.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

### Step 9: Submit for Review

1. Go to App Store Connect
2. Select your app
3. Click on version "1.0.0"
4. Fill all required information
5. Click "Submit for Review"
6. Wait 1-3 days for review

---

## 🔧 Post-Deployment Configuration

### Update Firebase with App Details

1. **Add Android App to Firebase** (if not done)
   - Firebase Console → Project Settings
   - Add Android app
   - Package name: `com.gourmetai.app`
   - Download `google-services.json`
   - Place in `android/app/`

2. **Add iOS App to Firebase** (if not done)
   - Firebase Console → Project Settings
   - Add iOS app
   - Bundle ID: `com.gourmetai.app`
   - Download `GoogleService-Info.plist`
   - Add to Xcode project

3. **Update Firestore Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /recipes/{recipeId} {
         allow read: if request.auth != null;
         allow create, update: if request.auth != null;
         allow delete: if request.auth != null && 
           (resource.data.userId == request.auth.uid || 
            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
       }
       match /ai_settings/{document=**} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
       }
     }
   }
   ```

### Domain Configuration

1. **SSL Certificate** - Already covered in web deployment
2. **DNS Settings** - Point A record to Hostinger IP
3. **Email Setup** - Configure email forwarding if needed

---

## 📊 Monitoring & Analytics

### Firebase Analytics
- Already integrated in your app
- View in Firebase Console → Analytics

### Google Play Console
- Track downloads, ratings, crashes
- View user reviews
- Monitor performance

### App Store Connect
- Track downloads and revenue
- View ratings and reviews
- Monitor crash reports

---

## 🔄 Updating Your Apps

### Web Updates
1. Make changes to code
2. Run `flutter build web --release`
3. Upload new files to Hostinger
4. Clear browser cache to test

### Android Updates
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment version
   ```
2. Build new AAB: `flutter build appbundle --release`
3. Upload to Google Play Console
4. Submit new release

### iOS Updates
1. Update version in Xcode
2. Build and archive
3. Upload to App Store Connect
4. Submit for review

---

## ⚠️ Common Issues & Solutions

### Web Deployment Issues

**Issue**: White screen after deployment
- **Solution**: Check browser console for errors
- Verify all files uploaded correctly
- Check `.htaccess` configuration

**Issue**: Firebase auth not working
- **Solution**: Verify domain in Firebase authorized domains
- Check API keys in Firebase config

### Android Issues

**Issue**: Signing error
- **Solution**: Verify key.properties file exists and has correct paths

**Issue**: Build fails
- **Solution**: Run `flutter clean` then rebuild

### iOS Issues

**Issue**: Provisioning profile error
- **Solution**: Open Xcode, go to Signing & Capabilities, click "Try Again"

**Issue**: Archive fails
- **Solution**: Clean build folder in Xcode (Cmd+Shift+K)

---

## 📞 Support Resources

- **Flutter Documentation**: https://docs.flutter.dev/
- **Firebase Support**: https://firebase.google.com/support
- **Google Play Support**: https://support.google.com/googleplay/android-developer
- **Apple Developer Support**: https://developer.apple.com/support/
- **Hostinger Support**: https://www.hostinger.com/tutorials

---

## ✅ Deployment Checklist

### Pre-Launch
- [ ] All features tested and working
- [ ] Firebase configured correctly
- [ ] OpenAI API key working
- [ ] Admin panel accessible
- [ ] Privacy policy created
- [ ] Terms of service created

### Web
- [ ] Built web app
- [ ] Uploaded to Hostinger
- [ ] SSL certificate active
- [ ] Domain pointing correctly
- [ ] Firebase authorized domains updated
- [ ] Tested on multiple browsers

### Android
- [ ] Keystore created and backed up
- [ ] App signed correctly
- [ ] Google Play Console account created
- [ ] Store listing complete
- [ ] Screenshots prepared
- [ ] Content rating completed
- [ ] AAB uploaded
- [ ] Submitted for review

### iOS
- [ ] Apple Developer account active
- [ ] Xcode project configured
- [ ] App Store Connect listing complete
- [ ] Screenshots prepared
- [ ] Privacy policy URL provided
- [ ] Build uploaded
- [ ] Submitted for review

---

## 🎉 Launch Day!

Once approved:
1. **Web**: Already live at your domain
2. **Android**: Will appear on Play Store
3. **iOS**: Will appear on App Store

**Marketing Tips:**
- Share on social media
- Create a landing page
- Write blog posts
- Contact tech reviewers
- Submit to app review sites
- Engage with users

---

## 📈 Next Steps After Launch

1. Monitor user feedback
2. Fix reported bugs quickly
3. Plan feature updates
4. Respond to reviews
5. Update analytics
6. Consider premium features
7. Build marketing strategy

---

Good luck with your launch! 🚀
