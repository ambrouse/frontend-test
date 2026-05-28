#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
COMPOSE_DIR="$DEPLOY_DIR/deploy/compose"
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
if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -d "$DEPLOY_DIR" ]]; then
  if [[ -f "$COMPOSE_DIR/.env" && -f "$COMPOSE_DIR/docker-compose.dev.yaml" ]]; then
    (cd "$DEPLOY_DIR" && docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml down --volumes --remove-orphans --rmi all || true)
  fi
  safe_remove_deploy_dir
fi
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":6929,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted Warehouse deploy and local Docker resources","progressPercent":100,"health":{"level":"ok","message":"Deleted"}}
EOF
printf '{"state":"deleted"}\n'
