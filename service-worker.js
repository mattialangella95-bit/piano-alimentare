// Cambia questo numero ogni volta che pubblichi un aggiornamento dei file:
// forza tutti i dispositivi a scaricare la nuova versione invece di usare la cache.
const CACHE_VERSION = 'piano-v9';
const CACHE_NAME = `piano-alimentare-${CACHE_VERSION}`;
const APP_SHELL = ['./index.html', './manifest.json', './icon-192.png', './icon-512.png', './supabase.js'];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Rete-prima per l'HTML (prende sempre l'ultima versione se c'è connessione),
// cache come riserva se il telefono è offline.
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  // Le chiamate a Supabase (login e salvataggi) vanno sempre in rete, mai in cache
  if (new URL(req.url).origin !== self.location.origin) return;

  if (req.mode === 'navigate' || req.destination === 'document') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req).then((res) => res || caches.match('./index.html')))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => cached || fetch(req))
  );
});
