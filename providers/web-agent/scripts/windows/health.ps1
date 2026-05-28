$ErrorActionPreference = "Stop"
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$Port = $env:AIHUB_BACKEND_PORT; if (-not $Port) { $Port = "6926" }
try {
  $Response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/api/v1/health" -UseBasicParsing -TimeoutSec 5
  $Ok = $Response.StatusCode -ge 200 -and $Response.StatusCode -lt 500
} catch {
  $Ok = $false
}
$Health = @{ ok=$Ok; url="http://127.0.0.1:$Port/api/v1/health"; checkedAt=(Get-Date).ToUniversalTime().ToString("o") }
New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Health | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\health.json" -Encoding utf8
$Health | ConvertTo-Json -Compress
if (-not $Ok) { exit 1 }
