#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-pdf-to-podcast}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PORT="${AIHUB_PORT:-7860}"
BRANCH="${AIHUB_BRANCH:-main}"
REPO_URL="https://github.com/PhuongHo03/pdf-to-podcast.git"
PROVIDER_ENV_KEYS=(
  NVIDIA_API_KEY
  ELEVENLABS_API_KEY
  API_SERVICE_PORT
  MAX_CONCURRENT_REQUESTS
  MODEL_API_URL
  DEFAULT_VOICE_1
  DEFAULT_VOICE_2
)

mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"

set_env_value() {
  local path="$1" key="$2" value="$3"
  [[ -n "$value" ]] || return 0
  if grep -Eq "^${key}=" "$path"; then
    sed -i.bak "s|^${key}=.*$|${key}=${value}|" "$path"
    rm -f "${path}.bak"
  else
    printf '\n%s=%s\n' "$key" "$value" >> "$path"
  fi
}

if [[ "${AIHUB_DRY_RUN:-0}" == "1" ]]; then
  mkdir -p "$DEPLOY_DIR"
elif [[ ! -d "$DEPLOY_DIR/.git" ]]; then
  if [[ -d "$DEPLOY_DIR" && -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]]; then
    rm -rf "$DEPLOY_DIR"
  fi
  git clone --branch "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
else
  git -C "$DEPLOY_DIR" fetch origin "$BRANCH"
  git -C "$DEPLOY_DIR" checkout "$BRANCH"
  git -C "$DEPLOY_DIR" pull --ff-only
fi

if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  ENV_FILE="$DEPLOY_DIR/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$DEPLOY_DIR/.env.example" "$ENV_FILE"
  fi

  for key in "${PROVIDER_ENV_KEYS[@]}"; do
    value="${!key:-}"
    set_env_value "$ENV_FILE" "$key" "$value"
  done
fi

python - "$ROOT/runtime/status.json" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone

json.dump({
    "projectId": sys.argv[2],
    "state": "installed",
    "pid": None,
    "port": int(sys.argv[3]),
    "platform": "linux",
    "startedAt": datetime.now(timezone.utc).isoformat(),
    "uptimeSec": 0,
    "currentStep": "Installed",
    "progressPercent": 100,
    "health": {"level": "ok", "message": "Installed"},
}, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
PY

printf '{"state":"installed","port":%s}\n' "$PORT"
