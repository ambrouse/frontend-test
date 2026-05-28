#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-agentic-commerce-blueprint}"

cleanup_compose_project() {
  local containers networks volumes
  containers=$(docker ps -aq --filter "label=com.docker.compose.project=${PROJECT_NAME}" 2>/dev/null || true)
  if [[ -n "$containers" ]]; then
    # shellcheck disable=SC2086
    docker rm -f $containers >/dev/null 2>&1 || true
  fi
  networks=$(docker network ls -q --filter "label=com.docker.compose.project=${PROJECT_NAME}" 2>/dev/null || true)
  if [[ -n "$networks" ]]; then
    # shellcheck disable=SC2086
    docker network rm $networks >/dev/null 2>&1 || true
  fi
  volumes=$(docker volume ls -q --filter "label=com.docker.compose.project=${PROJECT_NAME}" 2>/dev/null || true)
  if [[ -n "$volumes" ]]; then
    # shellcheck disable=SC2086
    docker volume rm -f $volumes >/dev/null 2>&1 || true
  fi
}

if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -d "$DEPLOY_DIR" ]]; then
  if [[ -f "$DEPLOY_DIR/docker-compose.yml" ]]; then
    (cd "$DEPLOY_DIR" && docker compose -p "$PROJECT_NAME" -f docker-compose.infra.yml -f docker-compose.yml down --volumes --remove-orphans --rmi all || true)
  fi
  cleanup_compose_project
  case "$(cd "$(dirname "$DEPLOY_DIR")" && pwd)/$(basename "$DEPLOY_DIR")" in
    "$(cd "$DEPLOY_ROOT" && pwd)"/*) rm -rf "$DEPLOY_DIR" ;;
    *) echo "Refusing to delete outside deploy root: $DEPLOY_DIR" >&2; exit 1 ;;
  esac
elif [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  cleanup_compose_project
fi
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"not_installed","pid":null,"port":6903,"platform":"linux","startedAt":null,"uptimeSec":0,"currentStep":"Deleted Agentic Commerce deploy and local Docker resources","progressPercent":100,"health":{"level":"ok","message":"Deleted"}}
EOF
printf '{"state":"deleted"}\n'
