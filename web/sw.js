const CACHE_NAME = 'glass-keep-v1.8.0';

// Assets to cache immediately on install
const PRECACHE_ASSETS = [
  './',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-maskable-192.png',
  'icons/icon-maskable-512.png',
  'canvaskit/canvaskit.wasm',
  'canvaskit/canvaskit.js'
];

// Install listener
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS).catch(err => {
        console.warn('Precache failed, some assets might be missing:', err);
      });
    })
  );
});

// Activate listener - cleanup old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => cacheName !== CACHE_NAME)
          .map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch listener - Improved Stale-While-Revalidate strategy
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);
  
  // Only handle local assets or specific CDNs (canvaskit, fonts)
  const isLocal = url.origin === self.location.origin;
  const isCanvaskit = url.href.includes('canvaskit.wasm') || url.href.includes('canvaskit.js');
  const isFont = url.hostname.includes('gstatic.com') || url.hostname.includes('googleapis.com');

  if (!isLocal && !isCanvaskit && !isFont) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((cachedResponse) => {
        const fetchPromise = fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            cache.put(event.request, networkResponse.clone());
          }
          return networkResponse;
        }).catch((err) => {
          console.warn('Network fetch failed, serving from cache if available:', err);
          return cachedResponse;
        });

        return cachedResponse || fetchPromise;
      });
    })
  );
});
