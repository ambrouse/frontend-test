#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-web-agent}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
if [ -x "$DEPLOY_DIR/stop.sh" ]; then
  "$DEPLOY_DIR/stop.sh" || true
fi
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"stopped","pid":null,"port":0,"platform":"linux","startedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","uptimeSec":0,"currentStep":"Stopped Web Agent","progressPercent":100,"health":{"level":"ok","message":"Stopped"}}
EOF
printf '{"state":"stopped"}\n'
