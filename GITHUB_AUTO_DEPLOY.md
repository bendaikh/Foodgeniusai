# 🚀 GitHub Auto-Deploy to Hostinger - Complete Setup Guide

## Automatically deploy your Flutter web app from GitHub to Hostinger

Every time you push code to GitHub, your website updates automatically! 🎉

---

## 📋 What You'll Set Up

```
Local Computer → GitHub → GitHub Actions → Hostinger
     ↓              ↓            ↓              ↓
   Make changes   Push code   Auto build    Auto deploy
```

**Benefits:**
- ✅ Push to GitHub → Website updates automatically
- ✅ No manual builds or uploads
- ✅ Version control (rollback if needed)
- ✅ Professional workflow
- ✅ Team collaboration ready

---

## 🎯 Overview

1. **Initialize Git** in your project
2. **Create GitHub repository**
3. **Push your code** to GitHub
4. **Set up GitHub Actions** (automated build)
5. **Configure FTP deployment** to Hostinger
6. **Test automatic deployment**

---

## PART 1: Setup Git & GitHub

### Step 1: Initialize Git Repository

Open PowerShell in your project:

```powershell
cd C:\Users\Espacegamers\Documents\gourmetai

# Initialize git repository
git init

# Check git status
git status
```

### Step 2: Create .gitignore File

**IMPORTANT:** Don't commit sensitive files!

Check if `.gitignore` exists:

```powershell
Get-Content .gitignore
```

If it doesn't have these entries, add them:

```powershell
# Add to .gitignore
Add-Content .gitignore @"

# Sensitive files (DO NOT COMMIT!)
android/key.properties
android/*.jks
android/*.keystore
.env
*.pem
*.key

# Firebase config (optional - some people commit this)
# lib/firebase_options.dart

# Build outputs
build/
.dart_tool/

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
"@
```

### Step 3: Create GitHub Repository

1. **Go to GitHub:**
   - Visit: https://github.com/
   - Sign in (or create account if needed)

2. **Create new repository:**
   - Click "+" (top right) → "New repository"
   - Repository name: `gourmetai` (or your preferred name)
   - Description: "AI-powered recipe generator app"
   - Visibility: **Private** (recommended) or Public
   - **Do NOT** initialize with README, .gitignore, or license
   - Click "Create repository"

3. **Copy repository URL:**
   - You'll see: `https://github.com/yourusername/gourmetai.git`
   - Keep this URL handy

### Step 4: Push Your Code to GitHub

In PowerShell:

```powershell
# Add all files
git add .

# Create first commit
git commit -m "Initial commit - GourmetAI app ready for deployment"

# Add remote repository (replace with your GitHub URL)
git remote add origin https://github.com/yourusername/gourmetai.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**If asked for credentials:**
- Username: Your GitHub username
- Password: Use **Personal Access Token** (not your password)

**To create Personal Access Token:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Select scopes: `repo` (full control)
4. Copy token and use as password

---

## PART 2: Get Hostinger FTP Credentials

### Step 1: Access FTP Settings

1. Login to Hostinger: https://www.hostinger.com/
2. Go to your hosting dashboard
3. Find **"FTP Accounts"** section
4. Note down or create FTP account:
   - **Host:** `ftp.yourdomain.com` or IP address
   - **Username:** Your FTP username
   - **Password:** Your FTP password
   - **Port:** `21`
   - **Remote Path:** `/public_html`

**If no FTP account exists:**
- Click "Create FTP Account"
- Choose directory: `/public_html`
- Set username and password
- Save credentials securely

---

## PART 3: Setup GitHub Actions for Auto-Deploy

### Step 1: Create GitHub Actions Workflow

Create folder structure:

```powershell
# Create .github/workflows folder
New-Item -ItemType Directory -Force -Path .github\workflows
```

### Step 2: Create Workflow File

Create file: `.github/workflows/deploy.yml`

```powershell
# Create the workflow file
New-Item -ItemType File -Force -Path .github\workflows\deploy.yml
```

Now edit `.github/workflows/deploy.yml` with this content:

```yaml
name: Deploy to Hostinger

on:
  push:
    branches: [ main ]  # Deploy when pushing to main branch
  workflow_dispatch:    # Allow manual trigger

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    # Step 1: Checkout code
    - name: Checkout repository
      uses: actions/checkout@v4
    
    # Step 2: Setup Flutter
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'  # or your Flutter version
        channel: 'stable'
    
    # Step 3: Get dependencies
    - name: Install dependencies
      run: flutter pub get
    
    # Step 4: Build web app
    - name: Build web
      run: flutter build web --release
    
    # Step 5: Deploy via FTP
    - name: Deploy to Hostinger via FTP
      uses: SamKirkland/FTP-Deploy-Action@v4.3.4
      with:
        server: ${{ secrets.FTP_SERVER }}
        username: ${{ secrets.FTP_USERNAME }}
        password: ${{ secrets.FTP_PASSWORD }}
        local-dir: ./build/web/
        server-dir: /public_html/
        dangerous-clean-slate: false
```

### Step 3: Add GitHub Secrets

**IMPORTANT:** Store FTP credentials securely in GitHub Secrets.

1. **Go to your GitHub repository**
2. Click **"Settings"** tab
3. Click **"Secrets and variables"** → **"Actions"**
4. Click **"New repository secret"**

**Add these 3 secrets:**

#### Secret 1: FTP_SERVER
- Name: `FTP_SERVER`
- Value: Your FTP host (e.g., `ftp.yourdomain.com` or IP address)
- Click "Add secret"

#### Secret 2: FTP_USERNAME
- Name: `FTP_USERNAME`
- Value: Your FTP username
- Click "Add secret"

#### Secret 3: FTP_PASSWORD
- Name: `FTP_PASSWORD`
- Value: Your FTP password
- Click "Add secret"

**Your secrets should look like:**
```
FTP_SERVER = ftp.yourdomain.com
FTP_USERNAME = your_ftp_username
FTP_PASSWORD = your_ftp_password
```

---

## PART 4: Test Automatic Deployment

### Step 1: Commit and Push Workflow

```powershell
# Add the workflow file
git add .github/workflows/deploy.yml

# Commit
git commit -m "Add GitHub Actions auto-deploy workflow"

# Push to GitHub
git push
```

### Step 2: Watch the Deployment

1. **Go to GitHub repository**
2. Click **"Actions"** tab
3. You'll see your workflow running
4. Click on the workflow run to see details

**Workflow steps:**
- ✓ Checkout repository
- ✓ Setup Flutter
- ✓ Install dependencies
- ✓ Build web
- ✓ Deploy to Hostinger via FTP

**Duration:** Usually 3-5 minutes

### Step 3: Verify Website Updated

1. Wait for GitHub Actions to complete (green checkmark)
2. Visit your website: `https://yourdomain.com`
3. Clear cache (Ctrl + Shift + R)
4. Verify changes are live

---

## PART 5: Daily Workflow (From Now On)

### Making Changes and Auto-Deploying

```powershell
# 1. Make changes to your code
# Edit files in VS Code or your IDE

# 2. Test locally
flutter run -d chrome

# 3. Commit changes
git add .
git commit -m "Add new feature: recipe filtering"

# 4. Push to GitHub (triggers auto-deploy!)
git push

# 5. Wait 3-5 minutes
# GitHub Actions builds and deploys automatically

# 6. Check your website
# Visit https://yourdomain.com
# Changes are live!
```

**That's it!** No manual building or FTP uploading needed! 🎉

---

## 🎨 Advanced: Deploy Different Branches

### Setup Staging Environment (Optional)

You can have different environments:
- `main` branch → Production (`yourdomain.com`)
- `staging` branch → Staging (`staging.yourdomain.com`)
- `dev` branch → No auto-deploy (local testing only)

**Modify `.github/workflows/deploy.yml`:**

```yaml
name: Deploy to Hostinger

on:
  push:
    branches: 
      - main      # Production
      - staging   # Staging

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    # ... (previous steps)
    
    # Deploy to different folders based on branch
    - name: Deploy to Hostinger
      uses: SamKirkland/FTP-Deploy-Action@v4.3.4
      with:
        server: ${{ secrets.FTP_SERVER }}
        username: ${{ secrets.FTP_USERNAME }}
        password: ${{ secrets.FTP_PASSWORD }}
        local-dir: ./build/web/
        server-dir: ${{ github.ref == 'refs/heads/main' && '/public_html/' || '/public_html/staging/' }}
```

**Create branches:**
```powershell
# Create staging branch
git checkout -b staging
git push -u origin staging

# Switch back to main
git checkout main
```

---

## 🔒 Security Best Practices

### 1. Protect Sensitive Files

**Never commit to GitHub:**
- ❌ `android/key.properties`
- ❌ `android/*.jks` (keystore files)
- ❌ `.env` files
- ❌ API keys or secrets

**Already in .gitignore:**
```
android/key.properties
android/*.jks
.env
```

### 2. Use Branch Protection

1. GitHub repository → Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass

### 3. Review Before Deploying

```powershell
# Create feature branch
git checkout -b feature/new-recipe-ui

# Make changes and commit
git add .
git commit -m "Update recipe UI"

# Push feature branch (won't auto-deploy)
git push -u origin feature/new-recipe-ui

# Create Pull Request on GitHub
# Review changes
# Merge to main → Auto-deploys!
```

---

## 📊 Monitoring Deployments

### Check Deployment Status

**In GitHub:**
1. Go to "Actions" tab
2. See all deployments
3. Green ✓ = Success
4. Red ✗ = Failed

**If deployment fails:**
1. Click on failed workflow
2. Check error messages
3. Common issues:
   - FTP credentials wrong
   - Flutter build error
   - Network timeout

### Deployment Notifications

**Get notified on deployment:**
1. GitHub repository → Settings → Notifications
2. Enable "Actions" notifications
3. Get email when deployment succeeds/fails

---

## 🔄 Rollback to Previous Version

**If something breaks:**

```powershell
# See commit history
git log --oneline

# Rollback to previous commit
git revert HEAD

# Or rollback to specific commit
git revert abc1234

# Push (triggers new deployment with old code)
git push
```

**Or use GitHub:**
1. Go to "Commits"
2. Find working version
3. Click "..." → "Revert"
4. Create pull request
5. Merge → Auto-deploys old working version

---

## 🚀 Alternative: Hostinger Git Integration (If Available)

Some Hostinger plans have built-in Git integration:

1. **Check if available:**
   - Hostinger dashboard → Look for "Git" or "Version Control"

2. **If available:**
   - Connect GitHub repository directly
   - Select branch to deploy
   - Auto-deploy on push

**Pros:**
- Easier setup
- No GitHub Actions needed
- Hostinger manages everything

**Cons:**
- Not all plans support this
- Less control over build process
- May not support Flutter builds

---

## 📝 Complete .gitignore Template

Here's a complete `.gitignore` for your project:

```gitignore
# Flutter/Dart
.dart_tool/
.packages
.pub-cache/
.pub/
build/

# Android
android/key.properties
android/*.jks
android/*.keystore
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/.generated/
ios/Runner/GeneratedPluginRegistrant.*
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.xcuserstate

# Sensitive files
.env
.env.local
.env.production
*.pem
*.key
secrets.yaml

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db
*.iml

# Web
.firebase/
firebase-debug.log
.firebase-debug.log

# Testing
coverage/
test/.test_coverage.dart

# Miscellaneous
*.class
*.log
*.pyc
*.swp
.atom/
.buildlog/
.history
.svn/
```

---

## 🎯 Quick Setup Checklist

- [ ] Git repository initialized
- [ ] .gitignore configured (no sensitive files)
- [ ] GitHub repository created
- [ ] Code pushed to GitHub
- [ ] FTP credentials obtained from Hostinger
- [ ] GitHub Actions workflow created (`.github/workflows/deploy.yml`)
- [ ] GitHub Secrets configured (FTP_SERVER, FTP_USERNAME, FTP_PASSWORD)
- [ ] First deployment tested and successful
- [ ] Website loads with changes

---

## 🆘 Troubleshooting

### GitHub Actions Failing

**Error: "FTP connection failed"**
```
Solution:
- Check FTP credentials in GitHub Secrets
- Verify FTP server address is correct
- Ensure FTP is enabled in Hostinger
- Check firewall/network settings
```

**Error: "Flutter build failed"**
```
Solution:
- Check Flutter version in workflow matches your local
- Verify pubspec.yaml is valid
- Check for build errors in Actions log
- Test build locally first: flutter build web --release
```

**Error: "Permission denied"**
```
Solution:
- Verify FTP username has write access to /public_html/
- Check server-dir path is correct
- Ensure Hostinger FTP account is active
```

### Website Not Updating

**Changes not appearing:**
1. Check GitHub Actions completed successfully (green checkmark)
2. Clear browser cache (Ctrl + Shift + Delete)
3. Try incognito/private window
4. Check file timestamps in Hostinger File Manager
5. Verify correct files were uploaded

### Firebase Auth Still Not Working After Deploy

**If Firebase auth breaks:**
1. Ensure domain is in Firebase authorized domains
2. Check Firebase config in deployed files
3. Verify SSL certificate is active
4. Clear browser cache completely

---

## 📈 Next Level: Add Build Checks

**Improve workflow with tests:**

```yaml
name: Deploy to Hostinger

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter analyze  # Check for errors
    - run: flutter test     # Run tests
  
  build-and-deploy:
    needs: test  # Only deploy if tests pass
    runs-on: ubuntu-latest
    steps:
    # ... (previous deploy steps)
```

---

## 🎉 You're All Set!

**Your new workflow:**

```
1. Write code locally
2. Test: flutter run -d chrome
3. Commit: git commit -m "Your changes"
4. Push: git push
5. Wait 3-5 minutes
6. Website automatically updates! 🚀
```

**No more manual:**
- ❌ Building web app
- ❌ Opening FTP client
- ❌ Uploading files
- ❌ Waiting for uploads

**Just push to GitHub and relax!** ☕

---

## 📞 Need Help?

**GitHub Actions not working?**
- Check Actions tab for error messages
- Verify secrets are set correctly
- Review workflow syntax

**FTP issues?**
- Test FTP credentials with FileZilla first
- Contact Hostinger support
- Check FTP is enabled in your hosting plan

**General Git help:**
- Git documentation: https://git-scm.com/doc
- GitHub guides: https://guides.github.com/

---

**Congratulations!** You now have a professional CI/CD pipeline! 🎊

Every code change automatically goes live - just like the pros! 🚀
