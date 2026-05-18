#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-pdf-to-podcast}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PORT="${AIHUB_PORT:-7860}"

mkdir -p "$ROOT/logs" "$ROOT/runtime"

if [[ -f "$DEPLOY_DIR/setup.sh" ]]; then
  (cd "$DEPLOY_DIR" && bash setup.sh --down)
fi

python - "$ROOT/runtime/status.json" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone

json.dump({
    "projectId": sys.argv[2],
    "state": "stopped",
    "pid": None,
    "port": int(sys.argv[3]),
    "platform": "linux",
    "startedAt": datetime.now(timezone.utc).isoformat(),
    "uptimeSec": 0,
    "currentStep": "Stopped",
    "progressPercent": 100,
    "health": {"level": "ok", "message": "Stopped"},
}, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
PY

printf '{"state":"stopped","port":%s}\n' "$PORT"
