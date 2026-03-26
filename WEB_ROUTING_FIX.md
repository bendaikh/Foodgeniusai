# Flutter Web Routing Configuration

## Problem
When using `usePathUrlStrategy()` in Flutter web, direct navigation to routes like `/admin` works locally but returns 404 in production. This happens because the server looks for an actual file at `/admin` instead of serving `index.html` and letting Flutter handle the routing.

## Solution
Configure your web server to redirect all requests to `index.html`. The configuration file you need depends on your hosting platform.

## Configuration Files (Choose Based on Your Host)

### 1. Firebase Hosting
**File:** `web/firebase.json`
- Already created in the `web` folder
- Redirects all requests to `index.html`
- Includes cache headers for static assets

**Deployment:**
```bash
firebase deploy --only hosting
```

### 2. Apache Server (.htaccess)
**File:** `web/.htaccess`
- Already created in the `web` folder
- Will be included when you build your Flutter app

**Deployment:**
- The `.htaccess` file will be copied to `build/web/.htaccess` automatically
- Upload the entire `build/web` folder to your Apache server

### 3. Vercel
**File:** `web/vercel.json`
- Already created in the `web` folder

**Deployment:**
```bash
vercel deploy
```

Or connect your GitHub repo to Vercel for automatic deployments.

### 4. Netlify
**Files:** `web/netlify.toml` or `web/_redirects`
- Both files created in the `web` folder (you only need one)
- `_redirects` is simpler and more common

**Deployment:**
```bash
netlify deploy --prod
```

Or connect your GitHub repo to Netlify for automatic deployments.

### 5. Nginx
If you're using Nginx, add this to your server configuration:

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    root /path/to/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 6. AWS S3 + CloudFront
In CloudFront:
- Go to Error Pages
- Create Custom Error Response
- HTTP Error Code: 404
- Customize Error Response: Yes
- Response Page Path: `/index.html`
- HTTP Response Code: 200

## Build and Deploy

1. **Build your Flutter web app:**
```bash
flutter build web --release
```

2. **The output will be in:** `build/web/`

3. **Deploy the `build/web` folder** to your hosting platform with the appropriate configuration file.

## Verification

After deployment, test these scenarios:

1. Navigate to your home page, then click to `/admin` - should work
2. Directly visit `https://yourdomain.com/admin` - should now work ✅
3. Refresh the page while on `/admin` - should stay on `/admin` ✅

## Current Routes in Your App

- `/landing` - Landing page
- `/admin` - Admin login
- `/setup-admin` - Admin setup
- `/test-firebase` - Firebase test
- `/fix-admin` - Admin password reset

All routes should now work with direct navigation!

## Notes

- The configuration files are in the `web` folder, so they'll be included in your build automatically
- Choose the configuration file that matches your hosting platform
- You don't need all the files - only the one for your specific host
- The rewrites ensure that Flutter's router handles all navigation
