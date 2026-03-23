# GourmetAI Android Deployment Script
# Run this script to build your Android app for Play Store

Write-Host "🤖 GourmetAI Android Deployment Script" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Check if keystore exists
if (-not (Test-Path "android\gourmetai-release-key.jks")) {
    Write-Host "⚠️  Keystore not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You need to create a keystore first. Run this command:" -ForegroundColor White
    Write-Host ""
    Write-Host "cd android" -ForegroundColor Cyan
    Write-Host "keytool -genkey -v -keystore gourmetai-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gourmetai" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then create android\key.properties file with your passwords." -ForegroundColor White
    Write-Host "See DEPLOYMENT_GUIDE.md for details." -ForegroundColor White
    exit 1
}

# Check if key.properties exists
if (-not (Test-Path "android\key.properties")) {
    Write-Host "⚠️  key.properties not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Create android\key.properties with:" -ForegroundColor White
    Write-Host "storePassword=YOUR_KEYSTORE_PASSWORD" -ForegroundColor Cyan
    Write-Host "keyPassword=YOUR_KEY_PASSWORD" -ForegroundColor Cyan
    Write-Host "keyAlias=gourmetai" -ForegroundColor Cyan
    Write-Host "storeFile=gourmetai-release-key.jks" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Step 1: Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Clean failed" -ForegroundColor Red
    exit 1
}

# Step 2: Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pub get failed" -ForegroundColor Red
    exit 1
}

# Step 3: Build App Bundle for Play Store
Write-Host "🔨 Building App Bundle (AAB) for Play Store..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Step 4: Build APK for testing (optional)
Write-Host "🔨 Building APK for testing..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  APK build failed (but AAB succeeded)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Your app files are ready:" -ForegroundColor Cyan
Write-Host "   - Play Store (AAB): build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
Write-Host "   - Testing (APK): build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to Google Play Console: https://play.google.com/console" -ForegroundColor White
Write-Host "2. Create a new app (if not already done)" -ForegroundColor White
Write-Host "3. Upload the AAB file" -ForegroundColor White
Write-Host "4. Complete the store listing" -ForegroundColor White
Write-Host "5. Submit for review" -ForegroundColor White
Write-Host ""
Write-Host "Opening build folder..." -ForegroundColor Yellow
Start-Process "explorer.exe" -ArgumentList "build\app\outputs\bundle\release"

Write-Host ""
Write-Host "🎉 Ready to upload to Play Store!" -ForegroundColor Green
