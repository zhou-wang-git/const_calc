self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const cacheKeys = await caches.keys();
      await Promise.all(cacheKeys.map((key) => caches.delete(key)));
    } catch (error) {
      console.error('flutter_service_worker cleanup failed', error);
    }

    try {
      await self.registration.unregister();
    } catch (error) {
      console.error('flutter_service_worker unregister failed', error);
    }

    const clients = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });

    await Promise.all(clients.map((client) => client.navigate(client.url)));
  })());
});
