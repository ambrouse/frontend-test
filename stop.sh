#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_LOG_DIR="${ROOT_DIR}/logs/hub"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-6902}"
FRONTEND_PORT="${AIHUB_FRONTEND_PORT:-6901}"

usage() {
  cat <<'EOF'
Usage: ./stop.sh [--providers] [--help]

Stops the local AI Hub dev services:
  - Nginx gateway from docker-compose.nginx.yml
  - Backend dev server on AIHUB_BACKEND_PORT, default 6902
  - Frontend dev server on AIHUB_FRONTEND_PORT, default 6901

Options:
  --providers  Also call each provider's Linux stop.sh wrapper.
  --help       Show this help.
EOF
}

log() {
  printf '%s\n' "$*"
}

warn() {
  printf '%s\n' "$*" >&2
}

pid_is_number() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

project_path() {
  local path="$1"
  [[ "$path" == "$ROOT_DIR" || "$path" == "$ROOT_DIR"/* ]]
}

process_cwd() {
  local pid="$1" cwd=""

  if [[ -d "/proc/$pid" ]]; then
    cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
    if [[ -n "$cwd" ]]; then
      printf '%s\n' "$cwd"
      return 0
    fi
  fi

  if command -v lsof >/dev/null 2>&1; then
    lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1
  fi
}

process_belongs_to_project() {
  local pid="$1" cwd cmd

  pid_is_number "$pid" || return 1
  kill -0 "$pid" 2>/dev/null || return 1

  cwd="$(process_cwd "$pid")"
  if [[ -n "$cwd" ]] && project_path "$cwd"; then
    return 0
  fi

  cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  [[ "$cmd" == *"$ROOT_DIR"* ]]
}

port_pids() {
  local port="$1"

  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | sort -u
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$port" 2>/dev/null \
      | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' \
      | sort -u
    return 0
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser "$port/tcp" 2>/dev/null | tr ' ' '\n' | sed '/^$/d' | sort -u
    return 0
  fi

  warn "Cannot inspect port $port because lsof, ss, and fuser are unavailable."
  return 0
}

child_pids() {
  local pid="$1" child
  if ! command -v pgrep >/dev/null 2>&1; then
    return 0
  fi

  pgrep -P "$pid" 2>/dev/null | while read -r child; do
    pid_is_number "$child" || continue
    printf '%s\n' "$child"
    child_pids "$child"
  done
}

pid_from_file() {
  local pid_file="$1"
  [[ -f "$pid_file" ]] || return 1
  tr -cd '0-9' < "$pid_file"
}

terminate_pids() {
  local label="$1"
  shift

  local pids=("$@")
  local pid children=()

  if [[ "${#pids[@]}" -eq 0 ]]; then
    log "OK: no $label process found."
    return 0
  fi

  for pid in "${pids[@]}"; do
    while IFS= read -r child; do
      children+=("$child")
    done < <(child_pids "$pid")
  done

  if [[ "${#children[@]}" -gt 0 ]]; then
    pids+=("${children[@]}")
  fi

  mapfile -t pids < <(printf '%s\n' "${pids[@]}" | awk 'NF && !seen[$0]++')
  log "Stopping $label: ${pids[*]}"
  kill "${pids[@]}" 2>/dev/null || true

  sleep 2

  local alive=()
  for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      alive+=("$pid")
    fi
  done

  if [[ "${#alive[@]}" -gt 0 ]]; then
    log "Force stopping $label: ${alive[*]}"
    kill -9 "${alive[@]}" 2>/dev/null || true
  fi
}

stop_pid_file() {
  local label="$1" pid_file="$2" pid
  pid="$(pid_from_file "$pid_file" || true)"
  if [[ -z "$pid" ]]; then
    rm -f "$pid_file"
    return 0
  fi

  terminate_pids "$label from ${pid_file#$ROOT_DIR/}" "$pid"
  rm -f "$pid_file"
}

stop_port_service() {
  local label="$1" port="$2"
  local pid scoped_pids=()

  while IFS= read -r pid; do
    pid_is_number "$pid" || continue
    if process_belongs_to_project "$pid"; then
      scoped_pids+=("$pid")
    else
      warn "Skipping PID $pid on port $port because it does not look like this project."
    fi
  done < <(port_pids "$port")

  terminate_pids "$label on port $port" "${scoped_pids[@]}"
}

stop_nginx_gateway() {
  if [[ ! -f "$ROOT_DIR/docker-compose.nginx.yml" ]]; then
    log "OK: no docker-compose.nginx.yml found."
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    log "OK: Docker is unavailable; skipping nginx gateway."
    return 0
  fi

  if docker compose version >/dev/null 2>&1; then
    log "Stopping nginx gateway..."
    (cd "$ROOT_DIR" && docker compose -f docker-compose.nginx.yml down --remove-orphans) || true
  else
    log "OK: Docker Compose is unavailable; skipping nginx gateway."
  fi
}

stop_providers() {
  local script
  while IFS= read -r script; do
    log "Stopping provider: ${script#$ROOT_DIR/}"
    (cd "$(dirname "$script")" && bash ./stop.sh) || true
  done < <(find "$ROOT_DIR/providers" -path '*/scripts/linux/stop.sh' -type f | sort)
}

STOP_PROVIDERS=0
for arg in "$@"; do
  case "$arg" in
    --providers) STOP_PROVIDERS=1 ;;
    --help|-h) usage; exit 0 ;;
    *) warn "Unknown option: $arg"; usage; exit 2 ;;
  esac
done

log "Stopping AI Hub..."
stop_nginx_gateway
stop_pid_file "backend" "$HUB_LOG_DIR/backend.pid"
stop_pid_file "frontend" "$HUB_LOG_DIR/frontend.pid"
stop_port_service "backend" "$BACKEND_PORT"
stop_port_service "frontend" "$FRONTEND_PORT"

if [[ "$STOP_PROVIDERS" -eq 1 ]]; then
  stop_providers
fi

log "Done."
