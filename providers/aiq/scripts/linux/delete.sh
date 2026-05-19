#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-aiq}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"

"$ROOT/scripts/linux/stop.sh" >/dev/null || true

COMPOSE_DIR="$DEPLOY_DIR/deploy"
if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -f "$COMPOSE_DIR/.env" && -f "$COMPOSE_DIR/docker-compose.yml" ]]; then
  (cd "$COMPOSE_DIR" && docker compose --env-file .env -f docker-compose.yml down --volumes --remove-orphans --rmi all || true)
fi

case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
  "$(cd "$DEPLOY_ROOT" && pwd)"/*) rm -rf "$DEPLOY_DIR" ;;
  *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
esac

cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":13080,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted","progressPercent":100,"health":{"level":"unknown","message":"Deleted"}}
EOF
printf '{"state":"not_installed"}\n'
