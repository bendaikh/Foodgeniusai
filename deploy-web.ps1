# GourmetAI Web Deployment Script
# Run this script to build your web app for deployment

Write-Host "🚀 GourmetAI Web Deployment Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

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

# Step 3: Build web app
Write-Host "🔨 Building web app..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Your web app files are in: build\web\" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to your Hostinger File Manager" -ForegroundColor White
Write-Host "2. Navigate to public_html folder" -ForegroundColor White
Write-Host "3. Upload all files from build\web\ folder" -ForegroundColor White
Write-Host "4. Make sure .htaccess file is configured (see DEPLOYMENT_GUIDE.md)" -ForegroundColor White
Write-Host "5. Visit your domain to test!" -ForegroundColor White
Write-Host ""
Write-Host "Opening build folder..." -ForegroundColor Yellow
Start-Process "explorer.exe" -ArgumentList "build\web"

Write-Host ""
Write-Host "🎉 Ready to deploy!" -ForegroundColor Green
