// FoodGeniusAI Service Worker for Enhanced Performance
// This service worker provides aggressive caching for better performance

'use strict';

const CACHE_NAME = 'foodgeniusai-cache-v2';
const DATA_CACHE_NAME = 'foodgeniusai-data-cache-v2';

// Files to cache immediately on install
const FILES_TO_CACHE = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/flutter_bootstrap.js',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/assets/FontManifest.json',
  '/assets/AssetManifest.json',
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[ServiceWorker] Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ServiceWorker] Pre-caching app shell');
      return cache.addAll(FILES_TO_CACHE);
    })
  );
  
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[ServiceWorker] Activating...');
  
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(
        keyList.map((key) => {
          if (key !== CACHE_NAME && key !== DATA_CACHE_NAME) {
            console.log('[ServiceWorker] Removing old cache', key);
            return caches.delete(key);
          }
        })
      );
    })
  );
  
  self.clients.claim();
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Handle API requests differently (network first)
  if (
    url.hostname.includes('firebasestorage.googleapis.com') ||
    url.hostname.includes('firebaseinstallations.googleapis.com') ||
    url.hostname.includes('identitytoolkit.googleapis.com') ||
    url.hostname.includes('firestore.googleapis.com') ||
    url.hostname.includes('api.openai.com')
  ) {
    event.respondWith(networkFirstStrategy(request));
    return;
  }
  
  // Handle Google Fonts (cache first)
  if (url.hostname.includes('fonts.googleapis.com') || url.hostname.includes('fonts.gstatic.com')) {
    event.respondWith(cacheFirstStrategy(request));
    return;
  }
  
  // Handle app resources (cache first with network fallback)
  event.respondWith(cacheFirstStrategy(request));
});

// Cache-first strategy for static assets
async function cacheFirstStrategy(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(request);
  
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('[ServiceWorker] Fetch failed:', error);
    
    // Return offline page if available
    if (request.destination === 'document') {
      return cache.match('/index.html');
    }
    
    throw error;
  }
}

// Network-first strategy for API calls
async function networkFirstStrategy(request) {
  const cache = await caches.open(DATA_CACHE_NAME);
  
  try {
    const networkResponse = await fetch(request);
    
    // Only cache successful GET requests
    if (networkResponse.ok && request.method === 'GET') {
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.log('[ServiceWorker] Network request failed, trying cache:', error);
    
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    throw error;
  }
}

// Handle skip waiting message
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
