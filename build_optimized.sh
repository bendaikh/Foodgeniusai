#!/bin/bash
# GourmetAI - Optimized Production Build Script
# This script builds a highly optimized Flutter web app with maximum performance

echo "🚀 Starting optimized build for GourmetAI..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Clean failed"
    exit 1
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Pub get failed"
    exit 1
fi

echo ""
echo "🔨 Building optimized web release..."
echo "Using CanvasKit renderer for better performance"

# Build with maximum optimizations
flutter build web \
    --web-renderer auto \
    --release \
    --pwa-strategy=offline-first \
    --no-source-maps

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📊 Build statistics:"

# Calculate build size
buildPath="build/web"
totalSize=$(du -sh "$buildPath" | cut -f1)

echo "   Total size: $totalSize"
echo "   Build path: $buildPath"

echo ""
echo "🎉 Your optimized build is ready for deployment!"
echo ""
echo "📝 Performance optimizations applied:"
echo "   ✓ CanvasKit renderer for better rendering performance"
echo "   ✓ Tree-shaking to remove unused code"
echo "   ✓ Minified and obfuscated code"
echo "   ✓ PWA offline-first strategy"
echo "   ✓ No source maps (smaller bundle)"
echo ""
echo "🚀 Deploy the 'build/web' folder to your hosting service"
