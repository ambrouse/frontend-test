$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot "aiq" }
$PortsPath = Join-Path $DeployDir ".runtime\ports.env"
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = "13080"; BACKEND_PORT = "18080" } }
$BackendPort = [int]$Ports.BACKEND_PORT
$FrontendPort = [int]$Ports.FRONTEND_PORT

$BackendOk = $false
$FrontendOk = $false
try { $BackendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$BackendPort/health" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch {}
try { $FrontendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$FrontendPort" -UseBasicParsing -TimeoutSec 5).StatusCode -ge 200 } catch {}

$Level = if ($BackendOk -and $FrontendOk) { "ok" } elseif ($BackendOk) { "warn" } else { "error" }
$Message = if ($BackendOk -and $FrontendOk) { "AI-Q backend and frontend are healthy" } elseif ($BackendOk) { "AI-Q backend healthy, frontend unavailable" } else { "AI-Q backend unavailable" }
$Result = @{ level=$Level; message=$Message; backendOk=$BackendOk; frontendOk=$FrontendOk; backendPort=$BackendPort; frontendPort=$FrontendPort; checkedAt=(Get-Date).ToUniversalTime().ToString("o") }
$Result | ConvertTo-Json -Compress
