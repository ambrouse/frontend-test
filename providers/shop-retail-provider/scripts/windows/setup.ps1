. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "shop-retail-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13000" }
$RepoUrl = "https://github.com/mionm/Shop-Retail-Provider-mion-.git"
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
Sync-Repo -RepoUrl $RepoUrl -Branch $Branch -DeployDir $DeployDir
if ($env:AIHUB_DRY_RUN -ne "1") {
  $ComposeFile = Join-Path $DeployDir "docker-compose.yaml"
  if (Test-Path -LiteralPath $ComposeFile) {
    $ComposeText = Get-Content -LiteralPath $ComposeFile -Raw
    $ComposeText = $ComposeText -replace "(?m)^\s*container_name:\s*.+\r?\n", ""
    $ComposeText = $ComposeText -replace "(?m)^\s*name:\s*retail-shopping-assistant_shopping-network\r?\n", ""
    Set-Content -LiteralPath $ComposeFile -Value $ComposeText -Encoding utf8
  }
  Copy-EnvIfMissing -Source (Join-Path $DeployDir ".env.example") -Target (Join-Path $DeployDir ".env")
  $EnvFile = Join-Path $DeployDir ".env"
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  $NvidiaKey = $env:NVIDIA_API_KEY
  if (-not $env:NGC_API_KEY -and $NvidiaKey) { $env:NGC_API_KEY = $NvidiaKey }
  foreach ($Key in @("NVIDIA_API_KEY","NGC_API_KEY","LLM_API_KEY","EMBED_API_KEY","RAIL_API_KEY")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if (($Key -in @("LLM_API_KEY","EMBED_API_KEY","RAIL_API_KEY","NGC_API_KEY")) -and -not $Value) { $Value = $NvidiaKey }
    $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value
  }
  $Text = Set-EnvValue -Text $Text -Key "CONFIG_OVERRIDE" -Value "config-build.yaml"
  $Text = Set-EnvValue -Text $Text -Key "COMPOSE_PROJECT_NAME" -Value "aihub-shop-retail-provider"
  $Text = Set-EnvValue -Text $Text -Key "HTTP_HOST_PORT" -Value $Port
  $DefaultPorts = @{
    CHAIN_SERVER_PORT = "18109"
    CATALOG_RETRIEVER_PORT = "18110"
    MEMORY_RETRIEVER_PORT = "18111"
    GUARDRAILS_PORT = "18112"
    MILVUS_PORT = "19531"
    MILVUS_HEALTH_PORT = "19091"
    MINIO_PORT = "19000"
    MINIO_CONSOLE_PORT = "19001"
    ETCD_PORT = "12379"
  }
  foreach ($Key in @("CHAIN_SERVER_PORT","CATALOG_RETRIEVER_PORT","MEMORY_RETRIEVER_PORT","GUARDRAILS_PORT","MILVUS_PORT","MILVUS_HEALTH_PORT","MINIO_PORT","MINIO_CONSOLE_PORT","ETCD_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if (-not $Value) { $Value = $DefaultPorts[$Key] }
    $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "installed" -Port ([int]$Port) -Step "Installed Shop Retail source"
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
