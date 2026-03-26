# GourmetAI Performance Optimization Guide

## Overview
This document outlines all performance optimizations applied to the GourmetAI Flutter web app to achieve better PageSpeed Insights scores and overall performance.

## Applied Optimizations

### 1. Web Renderer Optimization ✅
- **CanvasKit Renderer**: Configured to use CanvasKit instead of HTML renderer for better rendering performance
- **Configuration**: Set in `index.html` with engine initialization
- **Impact**: Significantly improves rendering performance and reduces layout shifts

### 2. HTML Performance Enhancements ✅
#### Meta Tags & Preloading
- Added viewport meta tag for proper mobile rendering
- Added preconnect hints for:
  - Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`)
  - Firebase Storage (`firebasestorage.googleapis.com`)
- Added DNS prefetch for Firebase services
- Improved meta descriptions and titles for SEO

#### Loading Experience
- Custom loading screen with brand colors
- Smooth fade-out transition when app loads
- Prevents "flash of unstyled content"

### 3. Animation Optimizations ✅
- **Removed Excessive AnimationControllers**: Eliminated constantly-running animation controllers on landing page
- **Simplified Icons**: Removed floating and pulsing animations that caused constant repaints
- **Reduced Complexity**: Simplified fallback animation in `CookingAnimation` widget
- **Impact**: Reduces CPU usage and improves frame rates

### 4. Code Optimizations ✅
- **Const Constructors**: Added const constructors throughout the app where possible
- **Widget Extraction**: Created separate const widgets (`_FooterItem`, `_GreenDot`, `_FooterText`)
- **Reduced Rebuilds**: Optimized widget tree to minimize unnecessary rebuilds
- **Impact**: Reduces memory usage and improves build performance

### 5. Build Configuration ✅
Created optimized build scripts (`build_optimized.ps1` and `build_optimized.sh`) with:
- CanvasKit renderer flag
- Tree-shaking enabled
- Minification and obfuscation
- No source maps (reduces bundle size)
- PWA offline-first strategy

### 6. Service Worker for Caching ✅
Implemented `flutter_service_worker.js` with:
- **Cache-First Strategy**: For static assets (app shell, fonts, images)
- **Network-First Strategy**: For API calls (Firebase, OpenAI)
- **Offline Support**: Serves cached content when offline
- **Cache Management**: Automatically cleans up old caches
- **Impact**: Dramatically improves repeat visit performance

### 7. Dependency Management ✅
- Optimized Lottie animation loading (falls back to simple icon if fails)
- Firebase lazy loading through configuration
- Reduced initial bundle size

## Build Instructions

### For Development
```bash
flutter run -d chrome
```

### For Production (Optimized)
```bash
# Windows
.\build_optimized.ps1

# Linux/Mac
chmod +x build_optimized.sh
./build_optimized.sh
```

## Deployment Recommendations

### 1. Enable Compression
Ensure your hosting provider enables:
- **Brotli compression** (preferred) or **Gzip**
- Configure for `.js`, `.wasm`, `.css`, `.html`, `.json` files

### 2. Set Cache Headers
Configure these cache headers in your hosting:

```
# Static assets (images, fonts, icons) - cache for 1 year
/assets/**/*
  Cache-Control: public, max-age=31536000, immutable

# JavaScript and WASM - cache for 1 year with immutable
/*.js
  Cache-Control: public, max-age=31536000, immutable
/*.wasm
  Cache-Control: public, max-age=31536000, immutable

# HTML - no cache (for service worker updates)
/index.html
  Cache-Control: no-cache, no-store, must-revalidate

# Service worker - no cache
/flutter_service_worker.js
  Cache-Control: no-cache, no-store, must-revalidate

# Manifest - cache for 1 week
/manifest.json
  Cache-Control: public, max-age=604800
```

### 3. Enable HTTP/2 or HTTP/3
Modern hosting providers should support HTTP/2 or HTTP/3 for:
- Multiplexing (parallel resource loading)
- Header compression
- Server push capabilities

### 4. CDN Configuration
If using a CDN:
- Enable automatic Brotli/Gzip compression
- Configure proper cache headers
- Enable HTTP/2/3
- Consider edge caching for Firebase assets

## Platform-Specific Configurations

### Netlify
Already configured in `web/netlify.toml`:
- Redirects for SPA routing
- Compression enabled
- Cache headers set

### Vercel
Already configured in `web/vercel.json`:
- Rewrites for SPA routing
- Headers configured

### Firebase Hosting
Already configured in `web/firebase.json`:
- Rewrites for SPA routing
- Clean URLs
- Headers configured

## Performance Monitoring

### Local Testing
```bash
# Build for production
flutter build web --release --web-renderer canvaskit

# Serve locally
cd build/web
python -m http.server 8000

# Test with Chrome DevTools Lighthouse
# Open: http://localhost:8000
```

### Production Testing
1. Deploy to your hosting provider
2. Test with Google PageSpeed Insights: https://pagespeed.web.dev/
3. Test with WebPageTest: https://www.webpagetest.org/
4. Monitor with Chrome User Experience Report

## Expected Performance Improvements

### Before Optimization
- Performance Score: ~30-40 (Poor)
- Large JavaScript bundle
- No caching strategy
- Excessive animations
- Slow initial load

### After Optimization
- Performance Score: ~70-90 (Good to Excellent)
- Optimized bundle size
- Aggressive caching
- Minimal animations
- Fast initial and repeat loads

## Troubleshooting

### Issue: CanvasKit takes too long to load
**Solution**: CanvasKit is ~2-3MB but provides better performance. Consider:
- Using CDN for CanvasKit (already configured)
- Enabling Brotli compression (reduces size by ~70%)

### Issue: Service worker not updating
**Solution**: 
- Clear browser cache
- Check service worker registration in DevTools
- Ensure `flutter_service_worker.js` has no-cache headers

### Issue: Still seeing poor performance
**Solutions**:
1. Check hosting compression is enabled
2. Verify cache headers are set correctly
3. Ensure CanvasKit renderer is being used (check DevTools)
4. Monitor network tab for slow resources
5. Check for console errors

## Additional Resources

- [Flutter Web Performance Best Practices](https://docs.flutter.dev/platform-integration/web/renderers)
- [Progressive Web App Checklist](https://web.dev/pwa-checklist/)
- [Optimize Web Performance](https://web.dev/fast/)

## Maintenance

### Regular Tasks
1. **Monitor Performance**: Use PageSpeed Insights monthly
2. **Update Dependencies**: Keep Flutter and packages updated
3. **Review Bundle Size**: Check after major updates
4. **Test Service Worker**: Verify caching works correctly
5. **Optimize Images**: Use WebP format for generated images when possible

### Future Optimizations
- [ ] Implement code splitting for admin routes
- [ ] Add image lazy loading for recipe cards
- [ ] Implement virtual scrolling for large recipe lists
- [ ] Consider WebAssembly for heavy computations
- [ ] Add resource hints for predicted navigation

---

**Last Updated**: 2026-03-25
**Version**: 1.0.0
