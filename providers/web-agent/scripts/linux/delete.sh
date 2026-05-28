#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-web-agent}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
SEARXNG_CONTAINER="${AIHUB_SEARXNG_CONTAINER:-web-agent-searxng}"
FRONTEND_PORT="${AIHUB_PORT:-6925}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-6926}"
safe_remove_deploy_dir() {
  case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
    "$(cd "$DEPLOY_ROOT" && pwd)"/*) ;;
    *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
  esac
  rm -rf "$DEPLOY_DIR" 2>/dev/null || {
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
      sudo chown -R "$(id -u):$(id -g)" "$DEPLOY_DIR"
      rm -rf "$DEPLOY_DIR"
    else
      echo "Cannot remove root-owned deploy directory: $DEPLOY_DIR" >&2
      exit 1
    fi
  }
}
stop_by_port() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    local pids
    pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
      kill $pids >/dev/null 2>&1 || true
      sleep 0.5
      kill -9 $pids >/dev/null 2>&1 || true
    fi
  fi
}
"$ROOT/scripts/linux/stop.sh" >/dev/null || true
stop_by_port "$BACKEND_PORT"
stop_by_port "$FRONTEND_PORT"
docker rm -f "$SEARXNG_CONTAINER" >/dev/null 2>&1 || true
safe_remove_deploy_dir
rm -rf "$ROOT/runtime"
printf '{"state":"deleted"}\n'
