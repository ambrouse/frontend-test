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
  "NVIDIA_API_KEY=$NvidiaApiKeyInput" | Set-Content -LiteralPath (Join-Path $RootDir ".env.local") -Encoding UTF8
  Write-Host "Wrote local key to .env.local (gitignored)."
}

$Python = Resolve-Python
if (!(Test-Path -LiteralPath $VenvDir)) {
  & $Python.Exe @($Python.Args) -m venv $VenvDir
}
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
& $VenvPython -m pip install --upgrade pip setuptools
& $VenvPython -m pip install -e "$RootDir/backend[dev]"

if (Test-Path -LiteralPath (Join-Path $RootDir "frontend/package-lock.json")) {
  npm.cmd ci --prefix (Join-Path $RootDir "frontend")
} else {
  npm.cmd install --prefix (Join-Path $RootDir "frontend")
}

& $VenvPython (Join-Path $RootDir "backend/scripts/seed_providers.py")

Write-Host "Setup complete."
Write-Host "Backend:  .\.venv\Scripts\python -m uvicorn app.main:app --reload --app-dir backend"
Write-Host "Frontend: cd frontend; npm run dev"
