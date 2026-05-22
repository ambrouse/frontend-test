$ErrorActionPreference = "SilentlyContinue"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "web-agent" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "3005" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8011" }

function Stop-ByPidFile {
  param([string]$PidFile)
  if (!(Test-Path -LiteralPath $PidFile)) { return }
  $PidValue = Get-Content -LiteralPath $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($PidValue) { Stop-Process -Id ([int]$PidValue) -Force -ErrorAction SilentlyContinue }
  Remove-Item -LiteralPath $PidFile -Force -ErrorAction SilentlyContinue
}

function Stop-ByPort {
  param([int]$Port)
  $Pids = @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | Where-Object { $_ -and $_ -ne 0 })
  foreach ($PidValue in $Pids) { Stop-Process -Id $PidValue -Force -ErrorAction SilentlyContinue }
}

function Stop-ProviderProcesses {
  $DeployFullPath = [System.IO.Path]::GetFullPath($DeployDir)
  Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -and $_.CommandLine.Contains($DeployFullPath)
  } | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
}

$LogDir = Join-Path $DeployDir "logs"
Stop-ByPidFile -PidFile (Join-Path $LogDir "backend.pid")
Stop-ByPidFile -PidFile (Join-Path $LogDir "frontend.pid")
Stop-ProviderProcesses
Stop-ByPort -Port ([int]$BackendPort)
Stop-ByPort -Port ([int]$FrontendPort)
Start-Sleep -Seconds 1
Stop-ProviderProcesses

$Status = @{ projectId=$Id; state="stopped"; pid=$null; port=0; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Stopped Web Agent"; progressPercent=100; health=@{ level="ok"; message="Stopped" } }
New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="stopped" } | ConvertTo-Json -Compress)
exit 0
