importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Paste the same Firebase web config you use in FlutterFire / firebase_options (web).
firebase.initializeApp({
  apiKey: 'AIzaSyAvUuFMgM0YE81NspqEYHovmIj1ND4i00c',
  appId: '1:787525828042:web:c11e35dc6bf20d8a9d6333',
  messagingSenderId: '787525828042',
  projectId: 'emergencyos-101',
  authDomain: 'emergencyos-101.firebaseapp.com',
  storageBucket: 'emergencyos-101.firebasestorage.app',
  measurementId: 'G-FV4D9EKCDS',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const title = payload.notification?.title || 'EmergencyOS Alert';
  const body = payload.notification?.body || 'New emergency nearby';
  const incidentId = payload.data?.incidentId || '';

  return self.registration.showNotification(title, {
    body: body,
    icon: '/favicon.png',
    badge: '/favicon.png',
    tag: 'sos-' + incidentId,
    renotify: true,
    requireInteraction: true,
    vibrate: [300, 100, 300, 100, 300],
    data: { incidentId: incidentId, action: 'OPEN_ALERT' },
  });
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const incidentId = event.notification.data?.incidentId || '';
  const url = incidentId ? '/?pendingIncidentId=' + incidentId : '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (windowClients) {
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
