#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-aiq}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"

"$ROOT/scripts/linux/stop.sh" >/dev/null || true

case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
  "$(cd "$DEPLOY_ROOT" && pwd)"/*) rm -rf "$DEPLOY_DIR" ;;
  *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
esac

cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":13080,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted","progressPercent":100,"health":{"level":"unknown","message":"Deleted"}}
EOF
printf '{"state":"not_installed"}\n'
