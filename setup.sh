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

find_venv_python() {
  local candidates=(
    "${VENV_DIR}/bin/python"
    "${VENV_DIR}/bin/python3"
    "${VENV_DIR}/Scripts/python.exe"
    "${VENV_DIR}/Scripts/python"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

python_major_minor() {
  "${PYTHON_BIN}" - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
}

install_python_venv_support() {
  local manager
  manager="$(detect_manager)"
  case "${manager}" in
    apt)
      local version
      version="$(python_major_minor)"
      install_packages apt "python${version}-venv" || install_packages apt python3-venv
      ;;
    dnf)
      install_packages dnf python3 python3-pip
      ;;
    pacman)
      install_packages pacman python python-pip
      ;;
    brew)
      install_packages brew python@3.12
      ;;
    *)
      echo "Install Python venv support manually, then rerun setup.sh." >&2
      return 1
      ;;
  esac
}

remove_venv_dir() {
  if [[ "${VENV_DIR}" != "${ROOT_DIR}/.venv" ]]; then
    echo "Refusing to remove unexpected venv path: ${VENV_DIR}" >&2
    return 1
  fi
  rm -rf -- "${VENV_DIR}"
}

create_venv() {
  if "${PYTHON_BIN}" -m venv "${VENV_DIR}"; then
    return 0
  fi

  if is_windows_bash; then
    echo "Could not create Python virtual environment. On Windows, run setup.ps1 from PowerShell." >&2
    return 1
  fi

  echo "Python venv support is missing or incomplete." >&2
  if prompt_install "Python venv support"; then
    install_python_venv_support
    remove_venv_dir
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
  else
    echo "Skipped Python venv support install." >&2
    return 1
  fi
}

print_backend_hints() {
  if is_windows_bash; then
    echo "Backend (PowerShell): .\\.venv\\Scripts\\python.exe -m uvicorn app.main:app --reload --app-dir backend"
    echo "Backend (Git Bash, reload): WATCHFILES_FORCE_POLLING=true ./.venv/Scripts/python.exe -m uvicorn app.main:app --reload --reload-dir backend --app-dir backend"
    echo "Backend (Git Bash, no reload): ./.venv/Scripts/python.exe -m uvicorn app.main:app --app-dir backend"
  else
    echo "Backend:  ./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend"
  fi
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

NVIDIA_API_KEY_INPUT=""
read -r -p "NVIDIA API key (optional, press Enter to skip): " NVIDIA_API_KEY_INPUT || true

if [[ -n "${NVIDIA_API_KEY_INPUT}" ]]; then
  {
    echo "NVIDIA_API_KEY=${NVIDIA_API_KEY_INPUT}"
  } > "${ROOT_DIR}/.env.local"
  echo "Wrote local key to .env.local (gitignored)."
fi

PYTHON_BIN="$(resolve_python)"
if [[ ! -d "${VENV_DIR}" ]]; then
  create_venv
fi
if ! VENV_PYTHON="$(find_venv_python)"; then
  echo "Existing venv is incomplete. Recreating ${VENV_DIR}..." >&2
  create_venv
  if ! VENV_PYTHON="$(find_venv_python)"; then
    echo "Could not locate venv python interpreter in ${VENV_DIR}." >&2
    echo "Expected one of: .venv/bin/python, .venv/bin/python3, or .venv/Scripts/python(.exe)." >&2
    exit 1
  fi
fi

"${VENV_PYTHON}" -m pip install --upgrade pip setuptools
pushd "${ROOT_DIR}/backend" >/dev/null
"${VENV_PYTHON}" -m pip install -e ".[dev]"
popd >/dev/null

if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
  npm ci --prefix "${ROOT_DIR}/frontend"
else
  npm install --prefix "${ROOT_DIR}/frontend"
fi

"${VENV_PYTHON}" "${ROOT_DIR}/backend/scripts/seed_providers.py"

echo "Setup complete."
print_backend_hints
echo "Frontend: cd frontend && npm run dev"
