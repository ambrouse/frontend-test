. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13001" }
$ApiPort = $env:API_GATEWAY_PORT; if (-not $ApiPort) { $ApiPort = "9000" }
$PgadminPort = $env:PGADMIN_PORT; if (-not $PgadminPort) { $PgadminPort = "5050" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
  $EnvFile = Join-Path $DeployDir ".env"
  if (!(Test-Path -LiteralPath $EnvFile)) {
    & "$Root\scripts\windows\setup.ps1"
  }
  if (!(Test-Path -LiteralPath $EnvFile)) { throw "AI Virtual Assistant setup did not create .env at $EnvFile" }
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  foreach ($Key in @("UI_PORT","API_GATEWAY_PORT","PGADMIN_PORT","AGENT_CHAIN_PORT","ANALYTICS_PORT","UNSTRUCTURED_RETRIEVER_PORT","STRUCTURED_RETRIEVER_PORT","POSTGRES_PORT","REDIS_PORT","REDIS_COMMANDER_PORT","MINIO_PORT","MINIO_CONSOLE_PORT","MILVUS_PORT","MILVUS_HEALTH_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if ($Value) { $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value }
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
  $OverrideDir = Join-Path $DeployDir ".runtime"
  New-Item -ItemType Directory -Force -Path $OverrideDir | Out-Null
  @"
services:
  pgadmin:
    volumes:
      - pgadmin_data:/var/lib/pgadmin
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql/data
  redis:
    volumes:
      - redis_data:/data
  etcd:
    volumes:
      - etcd_data:/etcd
  minio:
    volumes:
      - minio_data:/minio_data
  milvus:
    volumes:
      - milvus_data:/var/lib/milvus
volumes:
  postgres_data:
  pgadmin_data:
  redis_data:
  etcd_data:
  minio_data:
  milvus_data:
"@ | Set-Content -LiteralPath (Join-Path $OverrideDir "docker-compose.aihub.yaml") -Encoding utf8
  @"
services:
  milvus:
    image: milvusdb/milvus:v2.4.15
    deploy:
      resources:
        reservations:
          devices: []
"@ | Set-Content -LiteralPath (Join-Path $OverrideDir "docker-compose.cpu.yaml") -Encoding utf8
  $NgcKey = $env:NGC_API_KEY; if (-not $NgcKey) { $NgcKey = $env:NVIDIA_API_KEY }
  if ($NgcKey) { $NgcKey | docker login nvcr.io -u '$oauthtoken' --password-stdin | Out-Null }
  Push-Location $DeployDir
  try {
    $Args = @("--env-file",".env","-f","deploy/compose/docker-compose.yaml","-f",".runtime/docker-compose.aihub.yaml")
    if ($env:USE_CPU_MILVUS -ne "false") { $Args += @("-f",".runtime/docker-compose.cpu.yaml") }
    docker compose @Args build agent-chain-server api-gateway-server
    if ($LASTEXITCODE -ne 0) { throw "docker compose build failed" }
    if ($env:USE_LOCAL_NIM -eq "true") {
      docker compose @Args --profile local-nim up -d --force-recreate
    } else {
      docker compose @Args up -d --force-recreate
    }
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }
  } finally { Pop-Location }
  Wait-Http -Url "http://127.0.0.1:$ApiPort/agent/health" -Name "AI Virtual Assistant API gateway" -TimeoutSec 900
  Wait-Http -Url "http://127.0.0.1:$Port" -Name "AI Virtual Assistant UI" -TimeoutSec 300
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "running" -Port ([int]$Port) -Step "Running AI Virtual Assistant stack" -ExtraHealth @{ apiPort=[int]$ApiPort; deprecated=$true }
Write-Output (@{ state="running"; port=[int]$Port; apiPort=[int]$ApiPort } | ConvertTo-Json -Compress)
