#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PORT="${AIHUB_PORT:-8088}"
REPO_URL="https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
METRICS="$ROOT/runtime/metrics.json"

mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"
log_json() { python - "$1" "$2" "$3" >> "$LOG" <<'PY'
import json, sys
from datetime import datetime, timezone
print(json.dumps({"source": sys.argv[1], "level": sys.argv[2], "timestamp": datetime.now(timezone.utc).isoformat(), "message": sys.argv[3]}))
PY
}
status_json() { python - "$ID" "$PORT" "$1" "$2" "$3" > "$STATUS" <<'PY'
import json, sys
from datetime import datetime, timezone
print(json.dumps({"projectId": sys.argv[1], "state": sys.argv[3], "pid": None, "port": int(sys.argv[2]), "platform": "linux", "startedAt": datetime.now(timezone.utc).isoformat(), "uptimeSec": 0, "currentStep": sys.argv[4], "progressPercent": int(sys.argv[5]), "health": {"level": "ok", "message": sys.argv[4]}}, indent=2))
PY
}
patch_deploy_source() {
  local mcp_client="$DEPLOY_DIR/src/ui/hooks/useMCPClient.ts"
  [[ -f "$mcp_client" ]] || return 0
  python - "$mcp_client" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
updated = text.replace(
    "AbortSignal.timeout(65000), // 65s timeout for search agent (can take 20-30s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run search agent calls",
)
updated = updated.replace(
    "AbortSignal.timeout(65000), // 65s timeout for ARAG agent (takes ~25s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run agent calls",
)
if updated != text:
    path.write_text(updated, encoding="utf-8")
PY
}

log_json install info "install started"
if [[ "${AIHUB_DRY_RUN:-0}" == "1" ]]; then
  mkdir -p "$DEPLOY_DIR"
else
  if [[ ! -d "$DEPLOY_DIR/.git" ]]; then
    if [[ -d "$DEPLOY_DIR" ]] && [[ -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]]; then
      rm -rf "$DEPLOY_DIR"
    fi
    git clone --depth 1 --branch "${AIHUB_BRANCH:-main}" "$REPO_URL" "$DEPLOY_DIR"
  else
    git -C "$DEPLOY_DIR" fetch --depth 1 origin "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" checkout "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" pull --ff-only
  fi
  find "$DEPLOY_DIR" -name "*.sh" -type f -exec sed -i 's/\r$//' {} +
  patch_deploy_source
fi

if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
  cp "$ROOT/.env.example" "$DEPLOY_DIR/.env"
fi
python - "$DEPLOY_DIR/.env" "$PORT" <<'PY'
import os, sys
path, port = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
lines = []
seen_port = False
updates = {
    "NVIDIA_API_KEY": os.environ.get("NVIDIA_API_KEY", ""),
    "NGC_API_KEY": os.environ.get("NGC_API_KEY") or os.environ.get("NVIDIA_API_KEY", ""),
    "MERCHANT_API_KEY": os.environ.get("MERCHANT_API_KEY", ""),
    "PSP_API_KEY": os.environ.get("PSP_API_KEY", ""),
}
seen = set()
for line in text.splitlines():
    key = line.split("=", 1)[0] if "=" in line else ""
    if key == "HTTP_HOST_PORT":
        lines.append(f"HTTP_HOST_PORT={port}")
        seen_port = True
    elif key in updates and updates[key]:
        lines.append(f"{key}={updates[key]}")
        seen.add(key)
    else:
        lines.append(line)
if not seen_port:
    lines.append(f"HTTP_HOST_PORT={port}")
for key, value in updates.items():
    if key not in seen and value:
        lines.append(f"{key}={value}")
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
python - "$METRICS" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"sampledAt": datetime.now(timezone.utc).isoformat(), "platform": "linux", "process": {"cpuPercent": 0, "ramMb": 0, "gpuPercent": 0, "vramMb": 0}, "service": {"requestsTotal": 0, "requestsPerMin": 0, "latencyP50Ms": 0, "latencyP95Ms": 0, "errorsLastHour": 0}, "benchmark": {"headlineMetric": "installed", "secondaryMetric": "ready", "vramPeakMb": 0}}, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
PY
status_json installed "Installed into $DEPLOY_DIR" 100
log_json install info "install completed"
echo "{\"state\":\"installed\",\"port\":$PORT}"
