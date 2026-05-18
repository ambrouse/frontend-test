#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-aiq}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
BRANCH="${AIHUB_BRANCH:-develop}"
FRONTEND_PORT="${AIHUB_PORT:-13080}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-18080}"
NEXT_INTERNAL_PORT="${AIHUB_NEXT_INTERNAL_PORT:-$((FRONTEND_PORT + 1))}"
POSTGRES_PORT="${AIHUB_POSTGRES_PORT:-15432}"
REPO_URL="https://github.com/PhuongHo03/aiq.git"
PATCH_PATH="$ROOT/patches/windows-lifecycle.patch"

mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"

set_env_value() {
  local path="$1"
  local key="$2"
  local value="${3:-}"
  touch "$path"
  if grep -qE "^${key}=" "$path"; then
    python - "$path" "$key" "$value" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()
path.write_text("\n".join(f"{key}={value}" if line.startswith(f"{key}=") else line for line in lines) + "\n", encoding="utf-8")
PY
  else
    printf '%s=%s\n' "$key" "$value" >> "$path"
  fi
}

patch_applied() {
  grep -q "typing_extensions import override" "$DEPLOY_DIR/frontends/aiq_api/src/aiq_api/plugin.py" 2>/dev/null &&
    [ -f "$DEPLOY_DIR/frontends/ui/scripts/dev-next.js" ]
}

apply_provider_patch() {
  patch_applied && return 0
  git -C "$DEPLOY_DIR" apply --check "$PATCH_PATH"
  git -C "$DEPLOY_DIR" apply "$PATCH_PATH"
}

ensure_service_timeout() {
  local setup_script="$DEPLOY_DIR/setup.sh"
  [ -f "$setup_script" ] || return 0
  python - "$setup_script" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
updated = text.replace('local attempts=60', 'local attempts="${AIQ_SERVICE_START_ATTEMPTS:-180}"')
updated = updated.replace(
    'export NEXT_PUBLIC_BACKEND_URL="$BACKEND_URL"\n    export PORT="$FRONTEND_PORT"',
    'export NEXT_PUBLIC_BACKEND_URL="$BACKEND_URL"\n    export AIQ_FRONTEND_HOST="${AIQ_FRONTEND_HOST:-0.0.0.0}"\n    export PORT="$FRONTEND_PORT"',
)
if updated != text:
    path.write_text(updated, encoding="utf-8")
PY
}

ensure_frontend_host_binding() {
  local server_script="$DEPLOY_DIR/frontends/ui/server.js"
  [ -f "$server_script" ] || return 0
  python - "$server_script" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
updated = text.replace(
    "const hostname = process.env.HOSTNAME || '0.0.0.0'",
    "const hostname = process.env.AIQ_FRONTEND_HOST || process.env.HOST || '0.0.0.0'",
)
if updated != text:
    path.write_text(updated, encoding="utf-8")
PY
}

sync_provider_env() {
  local env_dir="$DEPLOY_DIR/deploy"
  local env_file="$env_dir/.env"
  [ -f "$env_file" ] || cp "$env_dir/.env.example" "$env_file"

  for key in NVIDIA_API_KEY TAVILY_API_KEY SERPER_API_KEY; do
    value="${!key:-}"
    set_env_value "$env_file" "$key" "$value"
  done

  local full_sources="false"
  if [ -n "${TAVILY_API_KEY:-}" ] && [ -n "${SERPER_API_KEY:-}" ]; then
    full_sources="true"
  fi
  set_env_value "$env_file" AIQ_REQUIRE_FULL_SOURCES "$full_sources"
  set_env_value "$env_file" AIQ_SUPPORT_SERVICES "${AIQ_SUPPORT_SERVICES:-false}"
  set_env_value "$env_file" AIQ_BACKEND_PORT "$BACKEND_PORT"
  set_env_value "$env_file" AIQ_FRONTEND_PORT "$FRONTEND_PORT"
  set_env_value "$env_file" AIQ_NEXT_INTERNAL_PORT "$NEXT_INTERNAL_PORT"
  set_env_value "$env_file" AIQ_POSTGRES_PORT "$POSTGRES_PORT"
  set_env_value "$env_file" REQUIRE_AUTH "false"
}

if [ "${AIHUB_DRY_RUN:-0}" = "1" ]; then
  mkdir -p "$DEPLOY_DIR"
elif [ ! -d "$DEPLOY_DIR/.git" ]; then
  [ ! -e "$DEPLOY_DIR" ] || rm -rf "$DEPLOY_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
else
  git -C "$DEPLOY_DIR" reset --hard
  git -C "$DEPLOY_DIR" fetch origin "$BRANCH"
  git -C "$DEPLOY_DIR" checkout "$BRANCH"
  git -C "$DEPLOY_DIR" pull --ff-only
fi

if [ "${AIHUB_DRY_RUN:-0}" != "1" ]; then
  apply_provider_patch
  ensure_service_timeout
  ensure_frontend_host_binding
  sync_provider_env
fi

cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"installed","pid":null,"port":$FRONTEND_PORT,"platform":"linux","startedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","uptimeSec":0,"currentStep":"Installed AI-Q provider","progressPercent":100,"health":{"level":"ok","message":"Installed","backendPort":$BACKEND_PORT}}
EOF
printf '{"state":"installed","port":%s,"backendPort":%s}\n' "$FRONTEND_PORT" "$BACKEND_PORT"
