#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

is_windows_bash() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_install() {
  local label="$1"
  local answer
  read -r -p "${label} is missing. Install it now if possible? [y/N]: " answer
  [[ "${answer}" =~ ^([yY]|yes|YES)$ ]]
}

sudo_cmd() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "sudo is required to install packages. Install manually, then rerun setup.sh." >&2
    return 1
  fi
}

detect_manager() {
  if command -v apt-get >/dev/null 2>&1; then echo "apt"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
  if command -v brew >/dev/null 2>&1; then echo "brew"; return; fi
  echo "none"
}

install_packages() {
  local manager="$1"
  shift
  case "${manager}" in
    apt)
      sudo_cmd apt-get update
      sudo_cmd apt-get install -y "$@"
      ;;
    dnf)
      sudo_cmd dnf install -y "$@"
      ;;
    pacman)
      sudo_cmd pacman -Sy --needed --noconfirm "$@"
      ;;
    brew)
      brew install "$@"
      ;;
    *)
      echo "No supported package manager detected. Install manually: $*" >&2
      return 1
      ;;
  esac
}

ensure_tool() {
  local label="$1"
  local command_name="$2"
  shift 2
  local packages=("$@")
  if command -v "${command_name}" >/dev/null 2>&1; then
    echo "OK: ${label}"
    return 0
  fi
  if is_windows_bash; then
    echo "${label} is missing. On Windows, run setup.ps1 from PowerShell for guided install." >&2
    return 1
  fi
  if prompt_install "${label}"; then
    install_packages "$(detect_manager)" "${packages[@]}"
  else
    echo "Skipped ${label} install." >&2
  fi
  command -v "${command_name}" >/dev/null 2>&1
}

resolve_python() {
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
    then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  if is_windows_bash; then
    echo "Python 3.11+ is required. On Windows, run setup.ps1 from PowerShell." >&2
    return 1
  fi
  if prompt_install "Python 3.11+"; then
    case "$(detect_manager)" in
      apt) install_packages apt python3 python3-venv python3-pip ;;
      dnf) install_packages dnf python3 python3-pip ;;
      pacman) install_packages pacman python python-pip ;;
      brew) install_packages brew python@3.12 ;;
      *) echo "Install Python 3.11+ manually, then rerun setup.sh." >&2; return 1 ;;
    esac
  fi

  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
    then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  echo "Python 3.11+ is still unavailable. Install it manually, then rerun setup.sh." >&2
  return 1
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "OK: Docker"
  elif ! is_windows_bash && prompt_install "Docker"; then
    case "$(detect_manager)" in
      apt) install_packages apt docker.io docker-compose-plugin ;;
      dnf) install_packages dnf docker docker-compose-plugin ;;
      pacman) install_packages pacman docker docker-compose ;;
      brew) install_packages brew docker docker-compose ;;
      *) echo "Install Docker manually, then rerun setup.sh." >&2 ;;
    esac
  else
    echo "Docker is optional for Hub boot, but required for real provider install/run." >&2
  fi

  if command -v docker >/dev/null 2>&1; then
    if ! docker compose version >/dev/null 2>&1; then
      echo "Docker Compose v2 is not responding. Install the compose plugin before provider install/run." >&2
    fi
    if ! docker info >/dev/null 2>&1; then
      echo "Docker daemon is not running. Start Docker Desktop/Engine before provider install/run." >&2
    fi
  fi
}

echo "AI Hub setup"
echo "This checks prerequisites, installs frontend/backend dependencies, and seeds provider manifests."

ensure_tool "Git" git git
ensure_tool "Node.js" node nodejs
ensure_tool "npm" npm npm
ensure_docker

read -r -p "NVIDIA API key (optional, press Enter to skip): " NVIDIA_API_KEY_INPUT

if [[ -n "${NVIDIA_API_KEY_INPUT}" ]]; then
  {
    echo "NVIDIA_API_KEY=${NVIDIA_API_KEY_INPUT}"
  } > "${ROOT_DIR}/.env.local"
  echo "Wrote local key to .env.local (gitignored)."
fi

PYTHON_BIN="$(resolve_python)"
if [[ ! -d "${VENV_DIR}" ]]; then
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi
VENV_PYTHON="${VENV_DIR}/bin/python"
"${VENV_PYTHON}" -m pip install --upgrade pip setuptools
"${VENV_PYTHON}" -m pip install -e "${ROOT_DIR}/backend[dev]"

if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
  npm ci --prefix "${ROOT_DIR}/frontend"
else
  npm install --prefix "${ROOT_DIR}/frontend"
fi

"${VENV_PYTHON}" "${ROOT_DIR}/backend/scripts/seed_providers.py"

echo "Setup complete."
echo "Backend:  ./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend"
echo "Frontend: cd frontend && npm run dev"
