# FoodGeniusAI Deployment Script for Hostinger
# This script builds the app and deploys it to the web repository

Write-Host "🚀 Starting FoodGeniusAI Deployment..." -ForegroundColor Cyan

# Step 1: Clean and build
Write-Host "`n📦 Building Flutter web app..." -ForegroundColor Yellow
flutter clean
flutter pub get
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Step 2: Copy to web repository
$webRepoPath = "..\Foodgeniusai_web"

if (-not (Test-Path $webRepoPath)) {
    Write-Host "`n📥 Cloning web repository..." -ForegroundColor Yellow
    Set-Location ..
    git clone https://github.com/bendaikh/Foodgeniusai_web.git
    Set-Location gourmetai
}

Write-Host "`n📋 Copying build files to web repository..." -ForegroundColor Yellow
Copy-Item -Path "build\web\*" -Destination $webRepoPath -Recurse -Force

# Step 3: Commit and push to web repo
Write-Host "`n🔄 Pushing to web repository..." -ForegroundColor Yellow
Set-Location $webRepoPath
git add .
git commit -m "Deploy FoodGeniusAI - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
    Write-Host "Your changes are now live on Hostinger after running 'git pull' there." -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Push failed!" -ForegroundColor Red
    exit 1
}

# Return to main project
Set-Location ..\gourmetai
Write-Host "`n🎉 Deployment complete!" -ForegroundColor Green
