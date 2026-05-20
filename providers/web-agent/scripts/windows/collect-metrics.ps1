$ErrorActionPreference = "SilentlyContinue"
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "3005" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8011" }
$BackendOk = $false
try { $BackendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$BackendPort/api/v1/health" -UseBasicParsing -TimeoutSec 5).StatusCode -lt 500 } catch {}
$FrontendOk = $false
try { $FrontendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$FrontendPort" -UseBasicParsing -TimeoutSec 5).StatusCode -lt 500 } catch {}
$SampledAt = (Get-Date).ToUniversalTime().ToString("o")
$Metrics = @{ sampledAt=$SampledAt; platform="windows"; process=@{ cpuPercent=0; ramMb=0; gpuPercent=0; vramMb=0 }; service=@{ backendOk=$BackendOk; frontendOk=$FrontendOk; backendPort=[int]$BackendPort; frontendPort=[int]$FrontendPort; requestsTotal=0; requestsPerMin=0; latencyP50Ms=0; latencyP95Ms=0; errorsLastHour=0 }; benchmark=@{ headlineMetric= if ($BackendOk -and $FrontendOk) { "healthy" } else { "not running" }; secondaryMetric="frontend $FrontendPort / backend $BackendPort"; latencyMs=0; throughput=0; vramPeakMb=0; measuredAt=$SampledAt } }
New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Metrics | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress -Depth 5
