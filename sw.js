// Service Worker FasoPermut — v2 (force cache refresh after audit fixes)
const CACHE_NAME = 'fasopermut-v2-2026-05-03';
const CORE = ['/', '/index.html', '/supabase.min.js', '/manifest.json'];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((c) => c.addAll(CORE).catch(() => {}))
  );
});

// Permet à la page de demander au SW de s'activer immédiatement (auto-update propre)
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Stratégie : network-first pour l'index, cache-first pour le reste
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  if (req.mode === 'navigate' || url.pathname === '/' || url.pathname.endsWith('.html')) {
    event.respondWith(
      fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((c) => c.put(req, copy)).catch(() => {});
        return res;
      }).catch(() => caches.match(req).then((r) => r || caches.match('/index.html')))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      if (res.ok) {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((c) => c.put(req, copy)).catch(() => {});
      }
      return res;
    }).catch(() => cached))
  );
});

// Push notifications
self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = { title: 'FasoPermut', body: event.data ? event.data.text() : 'Nouvelle activité' };
  }
  const title = data.title || '🎯 FasoPermut';
  const options = {
    body: data.body || 'Tu as un nouveau match !',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    tag: data.tag || 'fp-match',
    renotify: true,
    requireInteraction: false,
    data: { url: data.url || '/' },
    actions: [
      { action: 'open', title: 'Voir' },
      { action: 'close', title: 'Plus tard' }
    ]
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if (c.url.includes(location.origin) && 'focus' in c) {
          c.navigate(url); return c.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});

// Messages depuis la page (pour simuler une notif locale de match)
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'LOCAL_NOTIF') {
    const { title, body, url, tag } = event.data;
    self.registration.showNotification(title || 'FasoPermut', {
      body: body || '',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      tag: tag || 'fp-local',
      data: { url: url || '/' }
    });
  }
});
