# 🚀 GourmetAI Deployment Quick Start

## ✅ Complete Checklist

### Phase 1: Pre-Deployment (Do this first!)
- [ ] Test all app features locally
- [ ] Verify Firebase is working correctly
- [ ] Test OpenAI API integration
- [ ] Test admin panel functionality
- [ ] Backup your project
- [ ] Update version number in pubspec.yaml
- [ ] Upload privacy-policy.html to your website
- [ ] Upload terms-of-service.html to your website

---

## 🌐 Web Deployment (Hostinger) - Easiest & Fastest!

### Requirements
- [ ] Hostinger account with hosting plan
- [ ] Domain name configured
- [ ] FTP access or File Manager access

### Steps
1. **Build the app**
   ```powershell
   .\deploy-web.ps1
   ```
   Or manually:
   ```powershell
   flutter build web --release
   ```

2. **Upload to Hostinger**
   - Login to Hostinger control panel
   - Go to File Manager → public_html
   - Upload ALL files from `build\web\` folder
   - Upload `.htaccess` file

3. **Configure Firebase**
   - Firebase Console → Authentication → Authorized domains
   - Add: `yourdomain.com` and `www.yourdomain.com`

4. **Enable SSL**
   - Hostinger control panel → SSL
   - Enable free SSL certificate
   - Wait 10-15 minutes

5. **Test**
   - Visit: https://yourdomain.com
   - Test login, recipe generation, admin panel

### Estimated Time: 1-2 hours

---

## 🤖 Android Deployment (Google Play Store)

### Requirements
- [ ] Google Play Console account ($25 one-time)
- [ ] Android Studio installed
- [ ] Java/Keytool installed

### Steps

#### 1. Create Signing Key (One-time setup)
```powershell
cd android
keytool -genkey -v -keystore gourmetai-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gourmetai
```
**IMPORTANT**: Save the keystore file and passwords securely!

#### 2. Create key.properties
Create `android\key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gourmetai
storeFile=gourmetai-release-key.jks
```

#### 3. Update build.gradle
See DEPLOYMENT_GUIDE.md Section "Part 2, Step 1C"

#### 4. Build App
```powershell
.\deploy-android.ps1
```
Or manually:
```powershell
flutter build appbundle --release
```

#### 5. Prepare Store Assets
You need:
- App icon (512x512px)
- Feature graphic (1024x500px)
- Screenshots (at least 2, phone: 1080x1920px)
- Short description (80 chars)
- Full description (see DEPLOYMENT_GUIDE.md)

#### 6. Upload to Play Store
1. Go to https://play.google.com/console
2. Create new app
3. Complete store listing
4. Upload AAB file from: `build\app\outputs\bundle\release\app-release.aab`
5. Complete content rating
6. Set pricing & distribution
7. Submit for review

### Estimated Time: 4-6 hours (first time), 1-2 hours (updates)

---

## 🍎 iOS Deployment (Apple App Store)

### Requirements
- [ ] Mac computer with Xcode
- [ ] Apple Developer account ($99/year)
- [ ] Valid Apple ID

**Note**: iOS deployment REQUIRES a Mac. No Windows alternatives.

### Steps

#### 1. Setup Apple Developer Account
- Go to https://developer.apple.com/programs/
- Enroll in Apple Developer Program ($99/year)
- Wait 24-48 hours for approval

#### 2. Configure Xcode (On Mac)
```bash
cd ~/path/to/gourmetai
open ios/Runner.xcworkspace
```
- Select Runner → Signing & Capabilities
- Select your team
- Bundle ID: `com.gourmetai.app`
- Enable automatic signing

#### 3. Build App
```bash
flutter build ios --release
# Or
flutter build ipa --release
```

#### 4. Create App in App Store Connect
- Go to https://appstoreconnect.apple.com/
- Create new app
- Fill in app information
- Prepare screenshots (see DEPLOYMENT_GUIDE.md)

#### 5. Upload Build
In Xcode:
- Product → Archive
- Wait for archive
- Distribute App → App Store Connect → Upload

#### 6. Submit for Review
- Complete all app information
- Add build to version
- Submit for review
- Wait 1-3 days

### Estimated Time: 6-8 hours (first time), 2-3 hours (updates)

---

## 📋 Important Information

### Passwords & Keys to Save
- [ ] Keystore password (Android)
- [ ] Key alias password (Android)
- [ ] Apple ID app-specific password (iOS)
- [ ] FTP credentials (Hostinger)
- [ ] Firebase credentials
- [ ] OpenAI API key

**Store these in a secure password manager!**

### URLs You'll Need
- Firebase Console: https://console.firebase.google.com/
- Google Play Console: https://play.google.com/console
- App Store Connect: https://appstoreconnect.apple.com/
- Hostinger Control Panel: Your hosting dashboard
- Privacy Policy: https://yourdomain.com/privacy-policy.html
- Terms of Service: https://yourdomain.com/terms-of-service.html

---

## 🎯 Recommended Deployment Order

1. **Start with Web** (Easiest, fastest feedback)
   - Deploy to Hostinger
   - Test thoroughly
   - Get user feedback

2. **Then Android** (Larger market share)
   - Create Play Store listing
   - Upload app
   - Wait for approval (3-7 days)

3. **Finally iOS** (Requires Mac)
   - Setup Apple Developer account
   - Create App Store listing
   - Upload app
   - Wait for approval (1-3 days)

---

## 🆘 Getting Help

### Common Issues

**Web: White screen after deployment**
- Check browser console for errors
- Verify all files uploaded
- Check .htaccess configuration

**Android: Signing error**
- Verify key.properties exists and is correct
- Check keystore file path
- Ensure passwords are correct

**iOS: Provisioning error**
- Open Xcode
- Go to Signing & Capabilities
- Click "Try Again"

### Support Resources
- Flutter Docs: https://docs.flutter.dev/
- Firebase Support: https://firebase.google.com/support
- Google Play Help: https://support.google.com/googleplay/android-developer
- Apple Developer: https://developer.apple.com/support/
- Hostinger Support: https://www.hostinger.com/tutorials

---

## 📊 Post-Launch Checklist

After going live:
- [ ] Monitor user reviews
- [ ] Check analytics in Firebase
- [ ] Respond to user feedback
- [ ] Fix reported bugs
- [ ] Plan feature updates
- [ ] Market your app on social media
- [ ] Create landing page content
- [ ] Setup email marketing
- [ ] Monitor server performance
- [ ] Track conversion rates

---

## 🎉 Success Metrics

Track these after launch:
- Number of downloads/visits
- User registrations
- Active users (daily/monthly)
- Recipe generations
- User retention rate
- App rating/reviews
- Crash-free rate
- Response time

---

## 📅 Update Schedule Recommendation

- **Bug fixes**: Deploy immediately
- **Minor updates**: Every 2-4 weeks
- **Major features**: Every 1-3 months
- **Security updates**: As soon as possible

---

## 💰 Cost Summary

### One-time Costs
- Google Play Console: $25
- Apple Developer Program: $99/year
- Keystore creation: Free

### Recurring Costs
- Hostinger hosting: ~$2-10/month
- Firebase (depends on usage): Free tier available, ~$0-50/month
- OpenAI API: ~$10-100/month (usage-based)
- Apple Developer: $99/year
- Domain renewal: ~$10-15/year

**Estimated total first year**: $200-400
**Estimated yearly after**: $150-300

---

Good luck with your launch! 🚀🎊
