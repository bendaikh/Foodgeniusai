# GourmetAI Android Release Build Instructions

## 📱 Building Your Android App for Google Play Store

### Prerequisites
- Flutter SDK installed
- Android SDK installed
- Java Development Kit (JDK) installed
- Keystore created and configured

---

## Step 1: Create Your Signing Key (First Time Only)

### 1.1 Open PowerShell/Terminal

```powershell
cd C:\Users\Espacegamers\Documents\gourmetai\android
```

### 1.2 Generate Keystore

```powershell
keytool -genkey -v -keystore gourmetai-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gourmetai
```

### 1.3 Answer the Prompts

You'll be asked for:
- **Keystore password**: Create a strong password (remember this!)
- **Key password**: Can be same as keystore password
- **First and last name**: Your name or company name
- **Organizational unit**: Your department (e.g., "Development")
- **Organization**: Your company name (e.g., "GourmetAI")
- **City**: Your city
- **State**: Your state/province
- **Country code**: 2-letter code (e.g., "US", "UK", "CA")

**Example:**
```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name?
  [Unknown]:  John Doe
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  GourmetAI
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=John Doe, OU=Development, O=GourmetAI, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Enter key password for <gourmetai>
        (RETURN if same as keystore password):
```

### 1.4 Verify Keystore Created

After completion, you should see:
- File created: `gourmetai-release-key.jks`
- Confirmation message about keystore generation

---

## Step 2: Configure Signing

### 2.1 Create key.properties File

Copy the template:
```powershell
Copy-Item android\key.properties.template android\key.properties
```

Or create manually: `android\key.properties`

### 2.2 Edit key.properties

Replace the placeholders with your actual passwords:

```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=gourmetai
storeFile=gourmetai-release-key.jks
```

### 2.3 Secure Your Keys

**CRITICAL - BACKUP YOUR KEYSTORE!**

1. Copy `gourmetai-release-key.jks` to a secure location
2. Save passwords in a password manager
3. Make offline backup (USB drive, etc.)
4. Store in multiple secure locations

**⚠️ WARNING**: If you lose this keystore, you CANNOT update your app on Play Store!

---

## Step 3: Update App Information

### 3.1 Check pubspec.yaml Version

File: `pubspec.yaml`

```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# Example: 1.0.0+1 means version 1.0.0, build 1
```

Update for new releases:
- Patch update (bug fixes): `1.0.1+2`
- Minor update (new features): `1.1.0+3`
- Major update (breaking changes): `2.0.0+4`

### 3.2 Verify build.gradle.kts

File: `android\app\build.gradle.kts`

Should contain:
```kotlin
namespace = "com.gourmetai.app"
applicationId = "com.gourmetai.app"
```

✅ Already configured!

### 3.3 Verify AndroidManifest.xml

File: `android\app\src\main\AndroidManifest.xml`

Should show:
```xml
android:label="GourmetAI"
```

✅ Already configured!

---

## Step 4: Build Release APK/AAB

### 4.1 Clean Previous Builds

```powershell
flutter clean
flutter pub get
```

### 4.2 Build App Bundle (AAB) - For Play Store

```powershell
flutter build appbundle --release
```

**Output location:**
```
build\app\outputs\bundle\release\app-release.aab
```

### 4.3 Build APK (Optional) - For Testing

```powershell
flutter build apk --release
```

**Output location:**
```
build\app\outputs\flutter-apk\app-release.apk
```

### 4.4 Or Use Helper Script

```powershell
.\deploy-android.ps1
```

This script:
- Checks for keystore
- Cleans build
- Gets dependencies
- Builds AAB and APK
- Opens output folder

---

## Step 5: Test Your APK (Before Uploading)

### 5.1 Install APK on Physical Device

1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect device via USB
4. Run:

```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

Or manually:
1. Copy APK to device
2. Open file manager
3. Tap APK file
4. Allow installation from unknown sources if prompted
5. Install

### 5.2 Test All Features

- [ ] App launches correctly
- [ ] User can register/login
- [ ] Recipe generation works
- [ ] Images upload correctly
- [ ] Admin panel accessible
- [ ] No crashes
- [ ] Smooth performance

---

## Step 6: Prepare for Google Play Store

### 6.1 Create Google Play Developer Account

1. Go to: https://play.google.com/console/signup
2. Pay $25 one-time registration fee
3. Complete developer profile
4. Agree to terms

### 6.2 Create New App

1. Click "Create app"
2. Fill in:
   - **App name**: GourmetAI
   - **Default language**: English (United States)
   - **App or Game**: App
   - **Free or Paid**: Free (or Paid)
3. Accept declarations
4. Click "Create app"

### 6.3 Prepare Store Listing Assets

You'll need:

#### App Icon
- **Size**: 512x512 pixels
- **Format**: PNG (no transparency)
- **Content**: Your app logo

#### Feature Graphic
- **Size**: 1024x500 pixels
- **Format**: PNG or JPEG
- **Content**: Promotional banner

#### Screenshots (Minimum 2)
- **Phone**: 1080x1920 or 1080x2340 pixels
- **Tablet** (optional): 2048x1536 pixels
- **Content**: Show key features

#### Short Description (80 characters max)
```
AI-powered recipe generator and kitchen management tool
```

#### Full Description (4000 characters max)
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

---

## Step 7: Upload to Play Console

### 7.1 Complete App Content

Navigate through Play Console sections:

#### Dashboard
- Complete all required items marked with ❗

#### Store Presence → Main Store Listing
- Upload app icon
- Upload feature graphic
- Upload screenshots
- Add short description
- Add full description
- Add app category: Food & Drink

#### Store Presence → Store Settings
- Select app category
- Add email address
- Add privacy policy URL: `https://yourdomain.com/privacy-policy.html`

#### Grow → Store Presence → Main Store Listing
- Complete all required fields

### 7.2 Set Up App Content

#### App Access
- Select "All functionality is available without restrictions"
- Or specify if login required

#### Ads
- Choose: "No, my app does not contain ads" (or "Yes" if applicable)

#### Content Rating
1. Click "Start questionnaire"
2. Enter email address
3. Select category: "Utility, Productivity, Communication, or Other"
4. Answer questions honestly
5. Most recipe apps get "Everyone" rating
6. Submit

#### Target Audience and Content
- Select age groups (usually "18 and older")
- Complete all sections

#### News Apps
- Select "No" unless applicable

#### Data Safety
1. Complete data collection questionnaire
2. Specify what data you collect:
   - Email addresses (for authentication)
   - User names
   - Recipe data
3. Explain how data is used
4. Mention encryption and security

#### Government Apps
- Select "No"

### 7.3 Create Production Release

1. Go to "Production" in left sidebar
2. Click "Create new release"
3. Upload your AAB file:
   ```
   build\app\outputs\bundle\release\app-release.aab
   ```
4. Wait for upload to complete
5. Review any warnings (most can be ignored initially)

#### Release Name
```
1.0.0
```

#### Release Notes (What's New)
```
Initial release of GourmetAI

• AI-powered recipe generation
• User authentication and profiles
• Recipe saving and management
• Ingredient tracking
• Admin dashboard for content management
• Beautiful, modern UI
• Fast and responsive performance
```

### 7.4 Review and Rollout

1. Review all sections
2. Ensure no ❗ warnings remain
3. Click "Save"
4. Click "Review release"
5. Review summary
6. Click "Start rollout to Production"
7. Confirm rollout

---

## Step 8: Wait for Review

### Timeline
- **Initial review**: 3-7 days (first submission)
- **Updates**: 1-3 days (subsequent submissions)

### What Google Reviews
- App functionality
- Content appropriateness
- Privacy policy compliance
- Data safety accuracy
- Policy violations

### Possible Outcomes

#### ✅ Approved
- You'll receive email notification
- App goes live on Play Store within hours
- Users can search and install

#### ⚠️ Changes Requested
- Google may ask for clarifications
- Respond promptly via Play Console
- Make requested changes
- Resubmit

#### ❌ Rejected
- Review rejection reason
- Fix issues
- Resubmit
- Common reasons:
  - Privacy policy issues
  - Content rating incorrect
  - Missing permissions explanations
  - Crashes or bugs

---

## Step 9: Post-Launch

### Monitor Your App

#### Play Console Dashboard
- Check installs
- Monitor ratings and reviews
- View crash reports
- Track user acquisition

#### Respond to Reviews
- Reply to user feedback
- Address concerns
- Thank positive reviewers

#### Fix Issues Quickly
- Monitor crash reports
- Push updates for critical bugs
- Keep app updated

### Promote Your App

- Share on social media
- Create website landing page
- Submit to app review sites
- Encourage user reviews
- Create promotional materials

---

## Updating Your App

### For Bug Fixes and Updates

1. Update code
2. Increment version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment patch and build
   ```
3. Build new AAB:
   ```powershell
   flutter build appbundle --release
   ```
4. Upload to Play Console
5. Create new release
6. Add release notes explaining changes
7. Submit for review

### Version Numbering

- **Bug fixes**: 1.0.0 → 1.0.1 (increment patch)
- **New features**: 1.0.0 → 1.1.0 (increment minor)
- **Major changes**: 1.0.0 → 2.0.0 (increment major)
- **Build number**: Always increment (+1, +2, +3...)

---

## Troubleshooting

### Build Errors

**Error: "Keystore not found"**
```
Solution: Verify key.properties has correct path to .jks file
Check: android\key.properties
Ensure: storeFile=gourmetai-release-key.jks exists
```

**Error: "Signing configuration error"**
```
Solution: Verify passwords in key.properties are correct
Try: Recreate keystore if passwords forgotten (NEW APP REQUIRED)
```

**Error: "Build failed with exit code 1"**
```
Solution:
1. flutter clean
2. flutter pub get
3. flutter build appbundle --release
```

### Upload Errors

**Error: "Upload certificate has fingerprint..."**
```
Solution: Using wrong keystore
Fix: Ensure using same keystore as first upload
```

**Error: "Version code has been used before"**
```
Solution: Increment build number in pubspec.yaml
Change: version: 1.0.0+1 to version: 1.0.0+2
```

### App Rejected

**Privacy policy issues**
```
Solution: Ensure privacy-policy.html is accessible
Verify: https://yourdomain.com/privacy-policy.html works
Update: Privacy policy URL in Play Console
```

**Crash on startup**
```
Solution: Test APK on physical device before uploading
Check: Firebase configuration is correct
Verify: All permissions granted
```

---

## Security Checklist

- [ ] Keystore backed up in multiple locations
- [ ] Passwords stored in password manager
- [ ] key.properties added to .gitignore
- [ ] Firebase security rules configured
- [ ] API keys secured
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Data encryption enabled

---

## Resources

- Google Play Console: https://play.google.com/console
- Flutter Deployment: https://docs.flutter.dev/deployment/android
- Android App Bundle: https://developer.android.com/guide/app-bundle
- Play Store Guidelines: https://play.google.com/about/developer-content-policy/

---

## Quick Command Reference

```powershell
# Create keystore
keytool -genkey -v -keystore gourmetai-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gourmetai

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build AAB
flutter build appbundle --release

# Build APK
flutter build apk --release

# Install APK on device
adb install build\app\outputs\flutter-apk\app-release.apk

# Check device connected
adb devices

# View logs
adb logcat

# Run automated script
.\deploy-android.ps1
```

---

Good luck with your Play Store launch! 🚀
