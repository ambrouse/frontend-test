#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-web-agent}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
SEARXNG_CONTAINER="${AIHUB_SEARXNG_CONTAINER:-web-agent-searxng}"
"$ROOT/scripts/linux/stop.sh" >/dev/null || true
docker rm -f "$SEARXNG_CONTAINER" >/dev/null 2>&1 || true
case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
  "$DEPLOY_ROOT"/*) rm -rf "$DEPLOY_DIR" ;;
  *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
esac
rm -rf "$ROOT/runtime"
printf '{"state":"deleted"}\n'
