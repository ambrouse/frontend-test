$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "aiq" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "13080" }

function Find-Bash {
  $Candidates = @("C:\Program Files\Git\bin\bash.exe", "C:\Program Files\Git\usr\bin\bash.exe", "bash")
  foreach ($Candidate in $Candidates) {
    try { return (Get-Command $Candidate -ErrorAction Stop).Source } catch {}
  }
  throw "Git Bash or bash is required to run this provider"
}

function Read-PortMap {
  $Path = Join-Path $DeployDir ".runtime\ports.env"
  if (!(Test-Path $Path)) { return @{ FRONTEND_PORT = $FrontendPort; BACKEND_PORT = "18080"; NEXT_INTERNAL_PORT = "13081" } }
  return Get-Content $Path | ConvertFrom-StringData
}

function Get-PortProcessId {
  param([int]$Port)
  try {
    $Connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
    if ($Connection -and $Connection.OwningProcess) { return [int]$Connection.OwningProcess }
  } catch {}
  return $null
}

function Wait-Http {
  param([string]$Url, [string]$Name, [int]$Retries = 120)
  for ($i = 1; $i -le $Retries; $i++) {
    try {
      $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8
      if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 500) { return }
    } catch {}
    Start-Sleep -Seconds 2
  }
  throw "$Name did not become ready at $Url"
}

New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null

if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path $DeployDir)) {
    & (Join-Path $Root "scripts\windows\setup.ps1")
    if ($LASTEXITCODE -ne 0) { throw "setup failed while preparing deploy directory" }
  }

  $Bash = Find-Bash
  Push-Location $DeployDir
  try {
    & $Bash setup.sh --up
    if ($LASTEXITCODE -ne 0) { throw "AI-Q setup.sh --up failed" }
  } finally {
    Pop-Location
  }
}

$Ports = Read-PortMap
$BackendPort = [int]$Ports.BACKEND_PORT
$ActualFrontendPort = [int]$Ports.FRONTEND_PORT

if ($env:AIHUB_DRY_RUN -ne "1") {
  Wait-Http -Url "http://127.0.0.1:$BackendPort/health" -Name "AI-Q backend health"
  Wait-Http -Url "http://127.0.0.1:$BackendPort/v1/jobs/async/agents" -Name "AI-Q async agents"
  Wait-Http -Url "http://127.0.0.1:$ActualFrontendPort" -Name "AI-Q frontend"
}

$BackendPid = Get-PortProcessId -Port $BackendPort

$Status = @{ projectId=$Id; state="running"; pid=$BackendPid; port=$ActualFrontendPort; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running AI-Q backend and UI"; progressPercent=100; health=@{ level="ok"; message="Started"; backendPort=$BackendPort } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=$ActualFrontendPort; backendPort=$BackendPort } | ConvertTo-Json -Compress)
