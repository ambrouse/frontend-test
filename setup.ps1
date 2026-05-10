$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $RootDir ".venv"
$PythonCandidates = @("py -3.12", "py -3.11", "python")

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
  throw "Python 3.11+ is required. Install it with: winget install Python.Python.3.12"
}

Write-Host "AI Hub setup"
Write-Host "This installs frontend/backend dependencies and seeds provider manifests."
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
