. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "shop-retail-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13000" }
$ChainPort = $env:CHAIN_SERVER_PORT; if (-not $ChainPort) { $ChainPort = "18109" }
$CatalogPort = $env:CATALOG_RETRIEVER_PORT; if (-not $CatalogPort) { $CatalogPort = "18110" }
$MemoryPort = $env:MEMORY_RETRIEVER_PORT; if (-not $MemoryPort) { $MemoryPort = "18111" }
$RailsPort = $env:GUARDRAILS_PORT; if (-not $RailsPort) { $RailsPort = "18112" }
$MilvusPort = $env:MILVUS_PORT; if (-not $MilvusPort) { $MilvusPort = "19531" }
$MilvusHealthPort = $env:MILVUS_HEALTH_PORT; if (-not $MilvusHealthPort) { $MilvusHealthPort = "19091" }
$MinioPort = $env:MINIO_PORT; if (-not $MinioPort) { $MinioPort = "19000" }
$MinioConsolePort = $env:MINIO_CONSOLE_PORT; if (-not $MinioConsolePort) { $MinioConsolePort = "19001" }
$EtcdPort = $env:ETCD_PORT; if (-not $EtcdPort) { $EtcdPort = "12379" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path -LiteralPath $DeployDir)) { & "$Root\scripts\windows\setup.ps1" }
  & "$Root\scripts\windows\setup.ps1"
  Push-Location $DeployDir
  try {
    docker compose --env-file .env -f docker-compose.yaml up -d --build
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }
  } finally { Pop-Location }
  Wait-Http -Url "http://127.0.0.1:$Port/api/health" -Name "Shop Retail nginx health" -TimeoutSec 600
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "running" -Port ([int]$Port) -Step "Running Shop Retail stack" -ExtraHealth @{ chainPort=[int]$ChainPort }
Write-Output (@{ state="running"; port=[int]$Port; chainPort=[int]$ChainPort } | ConvertTo-Json -Compress)
