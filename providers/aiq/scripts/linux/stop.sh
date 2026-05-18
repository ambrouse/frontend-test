#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-aiq}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"

if [ -d "$DEPLOY_DIR" ]; then
  (cd "$DEPLOY_DIR" && ./setup.sh --down) || true
fi

mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"stopped","pid":null,"port":13080,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Stopped","progressPercent":100,"health":{"level":"unknown","message":"Stopped"}}
EOF
printf '{"state":"stopped"}\n'
