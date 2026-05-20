#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-web-agent}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
BRANCH="${AIHUB_BRANCH:-main}"
FRONTEND_PORT="${AIHUB_PORT:-3005}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8011}"
SEARXNG_PORT="${AIHUB_SEARXNG_PORT:-18080}"
SEARXNG_CONTAINER="${AIHUB_SEARXNG_CONTAINER:-web-agent-searxng}"
REPO_URL="https://github.com/baolnq-ai/web-agent.git"

mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"

set_env_value() {
  local path="$1"
  local key="$2"
  local value="${3:-}"
  touch "$path"
  python - "$path" "$key" "$value" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
text = path.read_text(encoding="utf-8-sig") if path.exists() else ""
lines = text.splitlines()
updated = False
for index, line in enumerate(lines):
    if line.startswith(f"{key}="):
        lines[index] = f"{key}={value}"
        updated = True
if not updated:
    lines.append(f"{key}={value}")
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

sync_env() {
  local root_env="$DEPLOY_DIR/.env"
  local backend_env="$DEPLOY_DIR/backend/.env"
  [ -f "$root_env" ] || cp "$DEPLOY_DIR/.env.example" "$root_env"
  [ -f "$backend_env" ] || cp "$DEPLOY_DIR/backend/.env.example" "$backend_env"
  set_env_value "$root_env" BACKEND_HOST "127.0.0.1"
  set_env_value "$root_env" BACKEND_PORT "$BACKEND_PORT"
  set_env_value "$root_env" FRONTEND_HOST "0.0.0.0"
  set_env_value "$root_env" FRONTEND_PORT "$FRONTEND_PORT"
  set_env_value "$root_env" PUBLIC_BACKEND_HOST "127.0.0.1"
  set_env_value "$root_env" AUTO_START_APPS "false"
  set_env_value "$root_env" POSTGRES_AUTO_START "false"
  set_env_value "$root_env" PGADMIN_AUTO_START "false"
  set_env_value "$root_env" SEARXNG_AUTO_START "true"
  set_env_value "$root_env" SEARXNG_PORT "$SEARXNG_PORT"
  set_env_value "$root_env" SEARXNG_CONTAINER_NAME "$SEARXNG_CONTAINER"
  set_env_value "$backend_env" APP_SEARXNG_BASE_URL "http://127.0.0.1:$SEARXNG_PORT"
  set_env_value "$backend_env" APP_SEARXNG_BACKUP_BASE_URLS ""
  [ -z "${LLM_BASE_URL:-}" ] || set_env_value "$root_env" LLM_BASE_URL "$LLM_BASE_URL"
  [ -z "${LLM_MODEL:-}" ] || set_env_value "$root_env" LLM_MODEL "$LLM_MODEL"
}

find_python312() {
  for cmd in python3.12 python3 python; do
    if command -v "$cmd" >/dev/null 2>&1 && "$cmd" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 12) else 1)
PY
    then
      command -v "$cmd"
      return 0
    fi
  done
  echo "Python 3.12 or newer is required" >&2
  return 1
}

if [ "${AIHUB_DRY_RUN:-0}" = "1" ]; then
  mkdir -p "$DEPLOY_DIR"
elif [ ! -d "$DEPLOY_DIR/.git" ]; then
  [ ! -e "$DEPLOY_DIR" ] || rm -rf "$DEPLOY_DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
else
  git -C "$DEPLOY_DIR" fetch --depth 1 origin "$BRANCH"
  git -C "$DEPLOY_DIR" checkout -f "$BRANCH"
  git -C "$DEPLOY_DIR" pull --ff-only
fi

if [ "${AIHUB_DRY_RUN:-0}" != "1" ]; then
  sync_env
  PYTHON_BIN="$(find_python312)"
  PATH="$(dirname "$PYTHON_BIN"):$PATH" "$DEPLOY_DIR/setup.sh"
fi

cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"installed","pid":null,"port":$FRONTEND_PORT,"platform":"linux","startedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","uptimeSec":0,"currentStep":"Installed Web Agent","progressPercent":100,"health":{"level":"ok","message":"Installed","backendPort":$BACKEND_PORT}}
EOF
printf '{"state":"installed","port":%s,"backendPort":%s}\n' "$FRONTEND_PORT" "$BACKEND_PORT"
