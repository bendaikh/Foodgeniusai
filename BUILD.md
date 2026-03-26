# Building GourmetAI for Production

## Quick Start

### Build with Optimizations (Recommended)

**Windows:**
```powershell
.\build_optimized.ps1
```

**Linux/Mac:**
```bash
chmod +x build_optimized.sh
./build_optimized.sh
```

This script will:
- Clean previous builds
- Install dependencies
- Build with CanvasKit renderer
- Enable all performance optimizations
- Create a production-ready build in `build/web/`

### Manual Build

If you prefer to build manually:

```bash
flutter build web \
  --web-renderer canvaskit \
  --release \
  --pwa-strategy=offline-first \
  --no-source-maps
```

## Deployment

After building, deploy the contents of `build/web/` to your hosting provider.

### Supported Platforms
- ✅ Netlify (configured in `web/netlify.toml`)
- ✅ Vercel (configured in `web/vercel.json`)
- ✅ Firebase Hosting (configured in `web/firebase.json`)
- ✅ Any static hosting service

## Performance Features

✨ This build includes:
- CanvasKit renderer for superior performance
- Service worker with aggressive caching
- Optimized animations and widgets
- Preconnect hints for external resources
- Progressive Web App (PWA) capabilities
- Minified and tree-shaken code

## Expected Results

Before optimization: ~30-40 PageSpeed score
After optimization: ~70-90 PageSpeed score

See `PERFORMANCE_OPTIMIZATION.md` for detailed information.
