#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -d "$DEPLOY_DIR" ]]; then
  if [[ -f "$DEPLOY_DIR/docker-compose.yml" ]]; then
    (cd "$DEPLOY_DIR" && docker compose -f docker-compose.infra.yml -f docker-compose.yml down --volumes --remove-orphans --rmi local || true)
  fi
  case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
    "$(cd "$DEPLOY_ROOT" && pwd)"/*) rm -rf "$DEPLOY_DIR" ;;
    *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
  esac
fi
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":8088,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted Agentic Commerce deploy and local Docker resources","progressPercent":100,"health":{"level":"ok","message":"Deleted"}}
EOF
printf '{"state":"deleted"}\n'
