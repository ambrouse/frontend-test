$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "aiq" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }

function Find-Bash {
  $Candidates = @("C:\Program Files\Git\bin\bash.exe", "C:\Program Files\Git\usr\bin\bash.exe", "bash")
  foreach ($Candidate in $Candidates) {
    try { return (Get-Command $Candidate -ErrorAction Stop).Source } catch {}
  }
  return $null
}

function Stop-PortProcess {
  param([int]$Port)
  try {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
      Select-Object -ExpandProperty OwningProcess -Unique |
      ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
  } catch {}
}

function Stop-UiOrphans {
  $UiDir = Join-Path $DeployDir "frontends\ui"
  if (!(Test-Path $UiDir)) { return }
  $ResolvedUiDir = [System.IO.Path]::GetFullPath($UiDir)
  Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -and $_.CommandLine.Contains($ResolvedUiDir) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

if (Test-Path $DeployDir) {
  $Bash = Find-Bash
  if ($Bash) {
    Push-Location $DeployDir
    try {
      & $Bash setup.sh --down
    } finally {
      Pop-Location
    }
  }
}

$PortsPath = Join-Path $DeployDir ".runtime\ports.env"
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = "13080"; BACKEND_PORT = "18080"; NEXT_INTERNAL_PORT = "13081" } }
Stop-PortProcess -Port ([int]$Ports.FRONTEND_PORT)
Stop-PortProcess -Port ([int]$Ports.NEXT_INTERNAL_PORT)
Stop-PortProcess -Port ([int]$Ports.BACKEND_PORT)
Stop-UiOrphans

New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Status = @{ projectId=$Id; state="stopped"; pid=$null; port=[int]$Ports.FRONTEND_PORT; platform="windows"; startedAt=$null; uptimeSec=0; currentStep="Stopped"; progressPercent=100; health=@{ level="unknown"; message="Stopped"; backendPort=[int]$Ports.BACKEND_PORT } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="stopped" } | ConvertTo-Json -Compress)
