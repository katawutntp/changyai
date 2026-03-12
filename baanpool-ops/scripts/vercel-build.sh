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

# Remove service worker to prevent stale cache issues
echo "=== Removing service worker cache ==="
rm -f build/web/flutter_service_worker.js

echo "=== Build complete ==="
