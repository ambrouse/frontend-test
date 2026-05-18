. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13001" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
Sync-Repo -RepoUrl "https://github.com/mionm/ai-virtual-assistant-provider.git" -Branch $Branch -DeployDir $DeployDir
if ($env:AIHUB_DRY_RUN -ne "1") {
  Copy-EnvIfMissing -Source (Join-Path $DeployDir ".env.example") -Target (Join-Path $DeployDir ".env")
  $EnvFile = Join-Path $DeployDir ".env"
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  $NvidiaKey = $env:NVIDIA_API_KEY
  if (-not $env:NGC_API_KEY -and $NvidiaKey) { $env:NGC_API_KEY = $NvidiaKey }
  $Text = Set-EnvValue -Text $Text -Key "UI_PORT" -Value $Port
  foreach ($Key in @("NVIDIA_API_KEY","NGC_API_KEY","USE_LOCAL_NIM","USE_CPU_MILVUS","PGADMIN_DEFAULT_EMAIL","PGADMIN_DEFAULT_PASSWORD","API_GATEWAY_PORT","PGADMIN_PORT","AGENT_CHAIN_PORT","ANALYTICS_PORT","UNSTRUCTURED_RETRIEVER_PORT","STRUCTURED_RETRIEVER_PORT","POSTGRES_PORT","REDIS_PORT","REDIS_COMMANDER_PORT","MINIO_PORT","MINIO_CONSOLE_PORT","MILVUS_PORT","MILVUS_HEALTH_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if ($Key -eq "NGC_API_KEY" -and -not $Value) { $Value = $NvidiaKey }
    if ($Value) { $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value }
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "installed" -Port ([int]$Port) -Step "Installed AI Virtual Assistant source"
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
