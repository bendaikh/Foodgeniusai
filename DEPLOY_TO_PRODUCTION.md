# 🚀 Deploy to Production - Quick Guide

## Prerequisites

✅ DodoPayment is configured in admin panel  
✅ You've tested locally  
✅ Firebase CLI is installed  
✅ You're logged into Firebase  

## Deployment Commands

### 1. Stop Development Server
Press `q` in the terminal running Flutter

### 2. Build Production App
```bash
flutter build web --release
```
**Wait time**: 2-5 minutes  
**Output**: `build/web/` folder with optimized code

### 3. Deploy to Firebase
```bash
firebase deploy --only hosting
```
**Wait time**: 1-2 minutes  
**Output**: Your live production URL

## Full Command Sequence

```bash
# Stop dev server (press 'q' in terminal)

# Build for production
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

## ⚠️ Important: Before Going Live

### Update DodoPayment to Live Mode

1. Go to https://dashboard.dodopayments.com
2. Switch to **Live Mode** (top right)
3. Get your **Live API Keys**
4. Update your admin panel:
   - Settings → DodoPayment Configuration
   - Enter **Live API Key** and **Live Business ID**
   - Toggle **Test Mode** to **OFF**
   - Click **Save**

## Verification Steps

After deployment:

1. ✅ Visit your production URL
2. ✅ Log into admin panel
3. ✅ Go to Settings → verify DodoPayment shows Live Mode
4. ✅ Go to Payments → verify products load
5. ✅ Create a small test payment (real card, small amount)
6. ✅ Check DodoPayments dashboard for the payment

## 🔄 Update After Changes

Whenever you make changes:

```bash
# 1. Build
flutter build web --release

# 2. Deploy
firebase deploy --only hosting
```

## 🆘 Troubleshooting

### Build Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

### Deploy Fails - Not Logged In
```bash
# Login to Firebase
firebase login
```

### Deploy Fails - Wrong Project
```bash
# Check current project
firebase projects:list

# Select correct project
firebase use your-project-id
```

### Deploy Fails - Missing firebase.json
Your `firebase.json` should look like:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## 📊 Post-Deployment Checklist

- [ ] Production URL loads correctly
- [ ] Admin login works
- [ ] DodoPayment in Live Mode
- [ ] Can create products
- [ ] Can generate checkouts
- [ ] Test payment processes successfully
- [ ] Webhooks are configured (see main guide)
- [ ] Revenue tracking works

## 🎯 Quick Deploy (After First Time)

```bash
flutter build web --release && firebase deploy --only hosting
```

## 📱 Monitor Your Deployment

- **Firebase Console**: https://console.firebase.google.com
- **DodoPayments Dashboard**: https://dashboard.dodopayments.com
- **Your Live App**: Check Firebase console for URL

## ⚡ Pro Tips

1. **Always test locally first** before deploying
2. **Keep test mode separate** - use test keys in development
3. **Deploy during low traffic** hours when possible
4. **Monitor errors** in Firebase console after deployment
5. **Have rollback ready** - keep previous build if needed

## 🔐 Security Reminder

Before going live:
- ✅ Switch DodoPayment to Live Mode
- ✅ Use Live API keys (not test keys)
- ✅ Set up webhooks for payment notifications
- ✅ Test with real (small) payment first
- ✅ Monitor dashboard for first few transactions

---

**Ready to deploy?** Run the commands above! 🚀
