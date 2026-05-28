. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "6904" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
Sync-Repo -RepoUrl "https://github.com/mionm/ai-virtual-assistant-provider.git" -Branch $Branch -DeployDir $DeployDir
if ($env:AIHUB_DRY_RUN -ne "1") {
  Copy-EnvIfMissing -Source (Join-Path $DeployDir ".env.example") -Target (Join-Path $DeployDir ".env")
  $EnvFile = Join-Path $DeployDir ".env"
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  function Test-PlaceholderSecret {
    param([string]$Value)
    return ($Value -match "^\[REDACTED_" -or $Value -match "^(changeme|your_|example|placeholder)$")
  }
  $LocalEnvFile = Join-Path (Resolve-Path "$Root\..\..") ".env.local"
  $LocalEnv = @{}
  if (Test-Path -LiteralPath $LocalEnvFile) {
    Get-Content -LiteralPath $LocalEnvFile | ForEach-Object {
      if ($_ -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$") {
        $LocalEnv[$Matches[1]] = $Matches[2].Trim('"', "'")
      }
    }
  }
  $NvidiaKey = $env:NVIDIA_API_KEY
  if ((-not $NvidiaKey -or (Test-PlaceholderSecret $NvidiaKey)) -and $LocalEnv.ContainsKey("NVIDIA_API_KEY")) { $NvidiaKey = $LocalEnv["NVIDIA_API_KEY"] }
  if ($NvidiaKey) { Set-Item -Path "Env:NVIDIA_API_KEY" -Value $NvidiaKey }
  if (-not $env:NGC_API_KEY -and $NvidiaKey) { $env:NGC_API_KEY = $NvidiaKey }
  $Text = Set-EnvValue -Text $Text -Key "UI_PORT" -Value $Port
  $DefaultHostedModel = "meta/llama-3.3-70b-instruct"
  if (-not [Environment]::GetEnvironmentVariable("APP_LLM_MODELNAME")) {
    $Text = Set-EnvValue -Text $Text -Key "APP_LLM_MODELNAME" -Value $DefaultHostedModel
  }
  if (-not [Environment]::GetEnvironmentVariable("GRAPH_TIMEOUT_IN_SEC")) {
    $Text = Set-EnvValue -Text $Text -Key "GRAPH_TIMEOUT_IN_SEC" -Value "240"
  }
  foreach ($Key in @("NVIDIA_API_KEY","NGC_API_KEY","APP_LLM_MODELNAME","GRAPH_TIMEOUT_IN_SEC","USE_LOCAL_NIM","USE_CPU_MILVUS","PGADMIN_DEFAULT_EMAIL","PGADMIN_DEFAULT_PASSWORD","API_GATEWAY_PORT","PGADMIN_PORT","AGENT_CHAIN_PORT","ANALYTICS_PORT","UNSTRUCTURED_RETRIEVER_PORT","STRUCTURED_RETRIEVER_PORT","POSTGRES_PORT","REDIS_PORT","REDIS_COMMANDER_PORT","MINIO_PORT","MINIO_CONSOLE_PORT","MILVUS_PORT","MILVUS_HEALTH_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if ((-not $Value -or (Test-PlaceholderSecret $Value)) -and $LocalEnv.ContainsKey($Key)) { $Value = $LocalEnv[$Key] }
    if ($Key -eq "NGC_API_KEY" -and -not $Value) { $Value = $NvidiaKey }
    if ($Value) { $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value }
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "installed" -Port ([int]$Port) -Step "Installed AI Virtual Assistant source"
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
