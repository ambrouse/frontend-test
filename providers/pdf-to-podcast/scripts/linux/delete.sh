#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-pdf-to-podcast}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
"$ROOT/scripts/linux/stop.sh" >/dev/null || true
if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -d "$DEPLOY_DIR" ]]; then
  if [[ -f "$DEPLOY_DIR/docker-compose.yml" ]]; then
    (cd "$DEPLOY_DIR" && docker compose -f docker-compose.yml down --volumes --remove-orphans --rmi all || true)
  fi
  case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
    "$(cd "$DEPLOY_ROOT" && pwd)"/*) rm -rf "$DEPLOY_DIR" ;;
    *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
  esac
fi
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":7860,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted PDF to Podcast deploy and local Docker resources","progressPercent":100,"health":{"level":"ok","message":"Deleted"}}
EOF
printf '{"state":"deleted"}\n'
