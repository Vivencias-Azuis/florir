#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

# Setup API if needed
cd "$ROOT/api"
bundle check > /dev/null 2>&1 || bundle install
bin/rails db:create db:migrate 2>/dev/null || true

# Setup web if needed
cd "$ROOT/web"
[ -d node_modules ] || npm install

# Create .env.local if missing
if [ ! -f .env.local ]; then
  cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
  echo "Created web/.env.local"
fi

# Free ports
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
lsof -ti :4000 | xargs kill -9 2>/dev/null || true

echo ""
echo "Starting Florir..."
echo "  API  → http://localhost:4000"
echo "  Web  → http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both."
echo ""

cleanup() {
  kill "$API_PID" "$WEB_PID" 2>/dev/null
  wait "$API_PID" "$WEB_PID" 2>/dev/null
  echo "Stopped."
}
trap cleanup INT TERM

cd "$ROOT/api" && bundle exec rails server -p 4000 &
API_PID=$!

cd "$ROOT/web" && npm run dev &
WEB_PID=$!

wait "$API_PID" "$WEB_PID"
