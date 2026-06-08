#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${ROOT_DIR}/logs/hub"
FRONTEND_PORT="${AIHUB_FRONTEND_PORT:-6901}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-6902}"
NGINX_PORT="${AIHUB_NGINX_PORT:-6900}"
ASSUME_YES="${AIHUB_ASSUME_YES:-0}"
STOP_PROVIDERS=0
STOP_DOCKER=1
DOCKER_SUDO=0

usage() {
  cat <<'EOF'
Usage: ./stop.sh [--yes] [--providers] [--keep-gateway] [--help]

Stops AI Hub services started by setup.sh.

Options:
  --yes           Do not prompt; stop matching services and ports.
  --providers     Also stop provider Docker containers and provider Linux stop scripts.
  --keep-gateway  Leave the Nginx Docker gateway running.
  --help          Show this help.

Environment:
  AIHUB_FRONTEND_PORT  Frontend port, default 6901
  AIHUB_BACKEND_PORT   Backend port, default 6902
  AIHUB_NGINX_PORT     Gateway port, default 6900
  AIHUB_ASSUME_YES=1   Same as --yes
EOF
}

log() {
  printf '[AI Hub] %s\n' "$*"
}

warn() {
  printf '[AI Hub] WARN: %s\n' "$*" >&2
}

confirm() {
  local prompt="$1" default="${2:-n}" answer
  if [[ "${ASSUME_YES}" == "1" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    [[ "${default}" == "y" ]]
    return
  fi
  read -r -p "${prompt} " answer || answer=""
  answer="${answer:-${default}}"
  [[ "${answer}" =~ ^([yY]|yes|YES)$ ]]
}

is_windows_bash() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

is_number() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

run_as_root() {
  if is_windows_bash; then
    return 127
  fi
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return $?
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return $?
  fi
  return 127
}

run_docker() {
  if [[ "${DOCKER_SUDO}" == "1" ]]; then
    run_as_root docker "$@"
  else
    docker "$@"
  fi
}

ensure_docker_access() {
  command -v docker >/dev/null 2>&1 || return 1
  if docker info >/dev/null 2>&1; then
    DOCKER_SUDO=0
    return 0
  fi
  if run_as_root docker info >/dev/null 2>&1; then
    DOCKER_SUDO=1
    return 0
  fi
  return 1
}

systemd_user_available() {
  command -v systemctl >/dev/null 2>&1 &&
    systemctl --user is-system-running >/dev/null 2>&1
}

port_pids() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null | sort -u
    return 0
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :${port}" 2>/dev/null | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' | sort -u
    return 0
  fi
  if command -v fuser >/dev/null 2>&1; then
    fuser "${port}/tcp" 2>/dev/null | tr ' ' '\n' | sed '/^$/d' | sort -u
    return 0
  fi
  if is_windows_bash && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
      "Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique" \
      2>/dev/null | tr -d '\r' | sed '/^$/d' | sort -u
    return 0
  fi
  return 0
}

pid_from_file() {
  local pid_file="$1"
  [[ -f "${pid_file}" ]] || return 1
  tr -cd '0-9' < "${pid_file}"
}

kill_pids() {
  local label="$1"
  shift
  local pids=("$@") pid alive=()
  [[ "${#pids[@]}" -gt 0 ]] || { log "OK: no ${label} process found."; return 0; }

  log "Stopping ${label}: ${pids[*]}"
  if is_windows_bash && command -v taskkill.exe >/dev/null 2>&1; then
    for pid in "${pids[@]}"; do
      taskkill.exe //PID "${pid}" //T //F >/dev/null 2>&1 || true
    done
    return 0
  fi

  kill "${pids[@]}" 2>/dev/null || true
  sleep 2
  for pid in "${pids[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      alive+=("${pid}")
    fi
  done
  if [[ "${#alive[@]}" -gt 0 ]]; then
    kill -9 "${alive[@]}" 2>/dev/null || true
  fi
}

stop_systemd_unit() {
  local label="$1" unit="ai-hub-$1.service"
  if is_windows_bash || ! systemd_user_available; then
    return 1
  fi
  if systemctl --user list-units --all --plain --no-legend "${unit}" 2>/dev/null | grep -q "${unit}"; then
    if confirm "Stop ${label} systemd user unit ${unit}? [y/N]:" "n"; then
      systemctl --user stop "${unit}" >/dev/null 2>&1 || true
      systemctl --user reset-failed "${unit}" >/dev/null 2>&1 || true
      log "OK: stopped ${unit}."
    else
      log "Kept ${unit}."
    fi
    return 0
  fi
  return 1
}

stop_pid_file() {
  local label="$1" pid_file="$2" pid
  stop_systemd_unit "${label}" || true
  pid="$(pid_from_file "${pid_file}" || true)"
  if [[ -z "${pid}" ]]; then
    rm -f "${pid_file}"
    log "OK: no ${label} pid file."
    return 0
  fi
  if confirm "Stop ${label} PID ${pid} from ${pid_file#${ROOT_DIR}/}? [y/N]:" "n"; then
    kill_pids "${label}" "${pid}"
    rm -f "${pid_file}"
  else
    log "Kept ${label} PID ${pid}."
  fi
}

stop_port() {
  local label="$1" port="$2" pids=() pid
  while IFS= read -r pid; do
    is_number "${pid}" && pids+=("${pid}")
  done < <(port_pids "${port}")
  if [[ "${#pids[@]}" -eq 0 ]]; then
    log "OK: no listener on ${label} port ${port}."
    return 0
  fi
  if confirm "Kill listener(s) on ${label} port ${port}: ${pids[*]}? [y/N]:" "n"; then
    kill_pids "${label} port ${port}" "${pids[@]}"
  else
    log "Kept ${label} port ${port} listener(s)."
  fi
}

stop_gateway() {
  [[ "${STOP_DOCKER}" == "1" ]] || { log "Keeping Nginx gateway by request."; return 0; }
  if [[ ! -f "${ROOT_DIR}/docker-compose.nginx.yml" ]]; then
    log "OK: no docker-compose.nginx.yml."
    return 0
  fi
  if ! ensure_docker_access || ! run_docker compose version >/dev/null 2>&1; then
    log "OK: Docker Compose unavailable; skipping gateway stop."
    return 0
  fi
  if confirm "Stop Docker Nginx gateway from docker-compose.nginx.yml? [y/N]:" "n"; then
    (cd "${ROOT_DIR}" && run_docker compose -f docker-compose.nginx.yml down --remove-orphans) || true
  else
    log "Kept Docker Nginx gateway."
  fi
}

stop_provider_scripts() {
  local script
  while IFS= read -r script; do
    if confirm "Run provider stop script ${script#${ROOT_DIR}/}? [y/N]:" "n"; then
      (cd "$(dirname "${script}")" && bash ./stop.sh) || true
    fi
  done < <(find "${ROOT_DIR}/providers" -path '*/scripts/linux/stop.sh' -type f 2>/dev/null | sort)
}

stop_provider_containers() {
  if ! ensure_docker_access; then
    warn "Docker daemon unavailable; skipping provider container scan."
    return 0
  fi
  local ids=()
  while IFS= read -r id; do
    [[ -n "${id}" ]] && ids+=("${id}")
  done < <(run_docker ps -aq --filter "label=aihub.provider" 2>/dev/null || true)
  if [[ "${#ids[@]}" -eq 0 ]]; then
    log "OK: no provider containers with label aihub.provider."
    return 0
  fi
  if confirm "Stop provider Docker containers (${ids[*]})? [y/N]:" "n"; then
    run_docker stop "${ids[@]}" >/dev/null 2>&1 || true
  fi
}

for arg in "$@"; do
  case "${arg}" in
    --yes|-y) ASSUME_YES=1 ;;
    --providers) STOP_PROVIDERS=1 ;;
    --keep-gateway) STOP_DOCKER=0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage; warn "Unknown option: ${arg}"; exit 2 ;;
  esac
done

log "Stopping AI Hub services."
stop_gateway
stop_pid_file "backend" "${LOG_DIR}/backend.pid"
stop_pid_file "frontend" "${LOG_DIR}/frontend.pid"
stop_port "backend" "${BACKEND_PORT}"
stop_port "frontend" "${FRONTEND_PORT}"
stop_port "Nginx gateway" "${NGINX_PORT}"

if [[ "${STOP_PROVIDERS}" == "1" ]]; then
  stop_provider_containers
  stop_provider_scripts
else
  log "Provider stop skipped. Use ./stop.sh --providers to include provider containers/scripts."
fi

log "Stop complete."
