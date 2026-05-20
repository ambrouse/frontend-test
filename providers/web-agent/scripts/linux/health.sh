#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8011}"
mkdir -p "$ROOT/runtime"
ok=false
if curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1; then
  ok=true
fi
cat > "$ROOT/runtime/health.json" <<EOF
{"ok":$ok,"url":"http://127.0.0.1:$BACKEND_PORT/api/v1/health","checkedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"}
EOF
cat "$ROOT/runtime/health.json"
[ "$ok" = true ]
