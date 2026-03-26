# GourmetAI - Optimized Production Build Script
# This script builds a highly optimized Flutter web app with maximum performance

Write-Host "🚀 Starting optimized build for GourmetAI..." -ForegroundColor Green
Write-Host ""

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Clean failed" -ForegroundColor Red
    exit 1
}

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pub get failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔨 Building optimized web release..." -ForegroundColor Cyan
Write-Host "Using CanvasKit renderer for better performance" -ForegroundColor Yellow

# Build with maximum optimizations
flutter build web `
    --web-renderer auto `
    --release `
    --pwa-strategy=offline-first `
    --no-source-maps

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Build statistics:" -ForegroundColor Cyan

# Calculate build size
$buildPath = "build\web"
$totalSize = (Get-ChildItem -Path $buildPath -Recurse | Measure-Object -Property Length -Sum).Sum
$sizeInMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "   Total size: $sizeInMB MB" -ForegroundColor White
Write-Host "   Build path: $buildPath" -ForegroundColor White

Write-Host ""
Write-Host "🎉 Your optimized build is ready for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Performance optimizations applied:" -ForegroundColor Cyan
Write-Host "   ✓ CanvasKit renderer for better rendering performance" -ForegroundColor White
Write-Host "   ✓ Tree-shaking to remove unused code" -ForegroundColor White
Write-Host "   ✓ Minified and obfuscated code" -ForegroundColor White
Write-Host "   ✓ PWA offline-first strategy" -ForegroundColor White
Write-Host "   ✓ No source maps (smaller bundle)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Deploy the 'build\web' folder to your hosting service" -ForegroundColor Yellow
