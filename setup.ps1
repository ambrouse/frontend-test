$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $RootDir ".venv"
$PythonCandidates = @("py -3.12", "py -3.11", "python")

function Test-Command {
  param([Parameter(Mandatory = $true)][string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Confirm-Install {
  param([Parameter(Mandatory = $true)][string]$Label)
  $Answer = Read-Host "$Label is missing. Install it now if possible? [y/N]"
  return $Answer -match "^(y|Y|yes|YES)$"
}

function Install-WithWinget {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$PackageId
  )
  if (!(Test-Command "winget")) {
    Write-Warning "winget is not available. Install $Label manually, then rerun setup.ps1."
    return
  }
  if (Confirm-Install $Label) {
    winget install --id $PackageId --exact --accept-package-agreements --accept-source-agreements
  } else {
    Write-Warning "Skipped $Label install."
  }
}

function Ensure-Tool {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$WingetId,
    [bool]$Required = $true
  )
  if (Test-Command $Command) {
    Write-Host "OK: $Label"
    return
  }
  Install-WithWinget $Label $WingetId
  if ($Required -and !(Test-Command $Command)) {
    throw "$Label is still unavailable in this shell. Open a new terminal after installing, then rerun setup.ps1."
  }
}

function Resolve-Python {
  foreach ($Candidate in $PythonCandidates) {
    $Parts = $Candidate -split " "
    $Exe = $Parts[0]
    $Args = @($Parts | Select-Object -Skip 1)
    try {
      & $Exe @Args -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" 2>$null
      if ($LASTEXITCODE -eq 0) { return @{ Exe = $Exe; Args = $Args } }
    } catch {
      continue
    }
  }

  Install-WithWinget "Python 3.12" "Python.Python.3.12"
  foreach ($Candidate in $PythonCandidates) {
    $Parts = $Candidate -split " "
    $Exe = $Parts[0]
    $Args = @($Parts | Select-Object -Skip 1)
    try {
      & $Exe @Args -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" 2>$null
      if ($LASTEXITCODE -eq 0) { return @{ Exe = $Exe; Args = $Args } }
    } catch {
      continue
    }
  }
  throw "Python 3.11+ is required. Open a new terminal after installing Python, then rerun setup.ps1."
}

function Test-DockerDaemon {
  if (!(Test-Command "docker")) { return $false }
  docker info *> $null
  return $LASTEXITCODE -eq 0
}

function Set-LocalEnvValue {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Value
  )
  $EnvFile = Join-Path $RootDir ".env.local"
  if (Test-Path -LiteralPath $EnvFile) {
    $Updated = $false
    $Pattern = "^\s*$([regex]::Escape($Name))="
    $Lines = Get-Content -LiteralPath $EnvFile
    $Output = foreach ($Line in $Lines) {
      if ($Line -match $Pattern) {
        $Updated = $true
        "$Name=$Value"
      } else {
        $Line
      }
    }
    if (!$Updated) {
      $Output += "$Name=$Value"
    }
    $Output | Set-Content -LiteralPath $EnvFile -Encoding UTF8
  } else {
    "$Name=$Value" | Set-Content -LiteralPath $EnvFile -Encoding UTF8
  }
}

function Get-VenvPython {
  $Candidate = Join-Path $VenvDir "Scripts\python.exe"
  if (Test-Path -LiteralPath $Candidate) { return $Candidate }
  return $null
}

function Test-PythonVersion {
  param([Parameter(Mandatory = $true)][string]$PythonPath)
  & $PythonPath -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" 2>$null
  return $LASTEXITCODE -eq 0
}

function New-ProjectVenv {
  & $Python.Exe @($Python.Args) -m venv $VenvDir
}

function Get-LanIp {
  try {
    $Ip = Get-NetIPAddress -AddressFamily IPv4 |
      Where-Object { $_.IPAddress -notmatch "^(127|169\.254)\." } |
      Select-Object -First 1 -ExpandProperty IPAddress
    if ($Ip) { return $Ip }
  } catch {
    return $null
  }
  return $null
}

Write-Host "AI Hub setup"
Write-Host "This checks prerequisites, installs frontend/backend dependencies, and seeds provider manifests."

Ensure-Tool "Git" "git" "Git.Git"
Ensure-Tool "Node.js LTS" "node" "OpenJS.NodeJS.LTS"
Ensure-Tool "npm" "npm" "OpenJS.NodeJS.LTS"
Ensure-Tool "Docker Desktop" "docker" "Docker.DockerDesktop" -Required:$false

if (Test-Command "docker") {
  docker compose version *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Docker Compose v2 is not responding. Update Docker Desktop before installing providers."
  }
  if (!(Test-DockerDaemon)) {
    Write-Warning "Docker daemon is not running. Start Docker Desktop before provider install/run."
  }
} else {
  Write-Warning "Docker is optional for Hub boot, but required for real provider install/run."
}

$NvidiaApiKeyInput = Read-Host "NVIDIA API key (optional, press Enter to skip)"

if ($NvidiaApiKeyInput) {
  Set-LocalEnvValue "NVIDIA_API_KEY" $NvidiaApiKeyInput
  Write-Host "Updated NVIDIA_API_KEY in .env.local (gitignored)."
}

$Python = Resolve-Python
if (!(Test-Path -LiteralPath $VenvDir)) {
  New-ProjectVenv
}
$VenvPython = Get-VenvPython
if (!$VenvPython) {
  Write-Warning "Existing venv is incomplete. Recreating $VenvDir..."
  if (Test-Path -LiteralPath $VenvDir) {
    Remove-Item -LiteralPath $VenvDir -Recurse -Force
  }
  New-ProjectVenv
  $VenvPython = Get-VenvPython
}
if (!$VenvPython) {
  throw "Could not locate venv python interpreter in $VenvDir."
}
if (!(Test-PythonVersion $VenvPython)) {
  Write-Warning "Existing venv Python is older than 3.11. Recreating $VenvDir..."
  Remove-Item -LiteralPath $VenvDir -Recurse -Force
  New-ProjectVenv
  $VenvPython = Get-VenvPython
  if (!$VenvPython -or !(Test-PythonVersion $VenvPython)) {
    throw "Could not create a Python 3.11+ virtual environment in $VenvDir."
  }
}
& $VenvPython -m pip install --upgrade pip setuptools
Push-Location (Join-Path $RootDir "backend")
& $VenvPython -m pip install -e ".[dev]"
Pop-Location

if (Test-Path -LiteralPath (Join-Path $RootDir "frontend/package-lock.json")) {
  npm.cmd ci --prefix (Join-Path $RootDir "frontend")
} else {
  npm.cmd install --prefix (Join-Path $RootDir "frontend")
}

& $VenvPython (Join-Path $RootDir "backend/scripts/seed_providers.py")

Write-Host "Setup complete."
Write-Host "Backend (PowerShell): .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 6902 --reload --app-dir backend"
Write-Host "Backend (Git Bash, reload): WATCHFILES_FORCE_POLLING=true ./.venv/Scripts/python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 6902 --reload --reload-dir backend --app-dir backend"
Write-Host "Backend (Git Bash, no reload): ./.venv/Scripts/python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 6902 --app-dir backend"
Write-Host "Frontend: cd frontend; `$env:API_PROXY_PORT=`"6902`"; npm run dev -- --hostname 0.0.0.0 --port 6901"
Write-Host "Nginx gateway: `$env:AIHUB_NGINX_PORT=`"6900`"; `$env:AIHUB_FRONTEND_UPSTREAM=`"host.docker.internal:6901`"; `$env:AIHUB_BACKEND_UPSTREAM=`"host.docker.internal:6902`"; docker compose -f docker-compose.nginx.yml up -d  # http://localhost:6900"
$LanIp = Get-LanIp
if ($LanIp) {
  Write-Host "LAN frontend: http://${LanIp}:6901"
  Write-Host "LAN gateway: http://${LanIp}:6900"
}
