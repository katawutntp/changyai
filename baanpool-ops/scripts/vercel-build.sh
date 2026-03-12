#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing Flutter SDK ==="
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version

# Generate .env from Vercel environment variables
echo "=== Generating .env ==="
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
LINE_CHANNEL_ID=${LINE_CHANNEL_ID:-}
LINE_CHANNEL_SECRET=${LINE_CHANNEL_SECRET:-}
LINE_MESSAGING_TOKEN=${LINE_MESSAGING_TOKEN:-}
EOF

echo "=== Building Flutter Web ==="
flutter pub get
flutter build web --release

# Replace service worker with self-destroying version to clear old caches
echo "=== Replacing service worker with self-destruct ==="
cat > build/web/flutter_service_worker.js << 'SWEOF'
// Self-destroying service worker: clears all caches and unregisters itself
self.addEventListener('install', function(e) {
  self.skipWaiting();
});
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(names.map(function(name) { return caches.delete(name); }));
    }).then(function() {
      return self.registration.unregister();
    }).then(function() {
      return self.clients.matchAll();
    }).then(function(clients) {
      clients.forEach(function(client) { client.navigate(client.url); });
    })
  );
});
SWEOF

echo "=== Build complete ==="
