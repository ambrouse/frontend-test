$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$PortsPath = Join-Path $DeployDir ".auto-ports.env"
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = "7860"; API_SERVICE_PORT = "8002" } }
$FrontendPort = [int]$Ports.FRONTEND_PORT
$ApiPort = [int]$Ports.API_SERVICE_PORT
$FrontendOk = $false
$ApiOk = $false
try { $FrontendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$FrontendPort" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch {}
try {
  $ApiHealth = Invoke-RestMethod -Uri "http://127.0.0.1:$ApiPort/health" -TimeoutSec 5
  $ApiOk = $ApiHealth.status -eq "healthy"
} catch {}
$Level = if ($FrontendOk -and $ApiOk) { "ok" } else { "error" }
@{ ok = ($FrontendOk -and $ApiOk); level = $Level; frontendPort = $FrontendPort; apiPort = $ApiPort } | ConvertTo-Json -Compress
