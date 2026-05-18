$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8091" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia"
$ProviderEnvKeys = @("NVIDIA_API_KEY", "EMBEDDING_API_KEY", "RAIL_API_KEY", "HOST_NGINX_PORT", "HOST_POSTGRES_PORT", "HOST_REDIS_PORT", "HOST_KAFKA_PORT", "HOST_ETCD_PORT", "HOST_MINIO_PORT", "HOST_MINIO_CONSOLE_PORT", "HOST_MILVUS_GRPC_PORT", "HOST_MILVUS_HTTP_PORT")

function Set-EnvValue {
  param([string]$Text, [string]$Key, [string]$Value)
  if ($null -eq $Value -or $Value -eq "") { return $Text }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    return ($Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value")
  }
  return ($Text.TrimEnd() + "`n$Key=$Value`n")
}

New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path (Join-Path $DeployDir "deploy\compose") | Out-Null
} elseif (!(Test-Path (Join-Path $DeployDir ".git"))) {
  if (Test-Path $DeployDir) {
    $ExistingItem = Get-ChildItem -Force -LiteralPath $DeployDir -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ExistingItem) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
  }
  git clone --depth 1 --branch $Branch $RepoUrl $DeployDir
} else {
  git -C $DeployDir fetch --depth 1 origin $Branch
  git -C $DeployDir checkout $Branch
  git -C $DeployDir pull --ff-only
}
$EnvFile = Join-Path $DeployDir "deploy\compose\.env"
New-Item -ItemType Directory -Force -Path (Split-Path $EnvFile) | Out-Null
if (!(Test-Path $EnvFile)) { Copy-Item "$Root\.env.example" $EnvFile }
$Text = Get-Content $EnvFile -Raw
$DefaultText = Get-Content "$Root\.env.example" -Raw
$ResolvedNvidiaApiKey = $env:NVIDIA_API_KEY
foreach ($Line in ($DefaultText -split "`r?`n")) {
  if ($Line -match '^([A-Za-z_][A-Za-z0-9_]*)=') {
    $Key = $Matches[1]
    if ($Text -notmatch "(?m)^$([regex]::Escape($Key))=") {
      $Text += "`n$Line"
    }
  }
}
$Text = $Text -replace '(?m)^BACKEND_PORT=.*$', "BACKEND_PORT=$BackendPort"
$Text = $Text -replace '(?m)^HOST_BACKEND_PORT=.*$', "HOST_BACKEND_PORT=$BackendPort"
$Text = $Text -replace '(?m)^FRONTEND_PORT=.*$', "FRONTEND_PORT=$Port"
$Text = $Text -replace '(?m)^HOST_FRONTEND_PORT=.*$', "HOST_FRONTEND_PORT=$Port"
$Text = $Text -replace '(?m)^LLM_MODEL=meta/llama-3\.1-70b-instruct$', "LLM_MODEL=nvidia/llama-3.3-nemotron-super-49b-v1.5"
if ($Text -notmatch '(?m)^BACKEND_PORT=') { $Text += "`nBACKEND_PORT=$BackendPort" }
if ($Text -notmatch '(?m)^HOST_BACKEND_PORT=') { $Text += "`nHOST_BACKEND_PORT=$BackendPort" }
if ($Text -notmatch '(?m)^FRONTEND_PORT=') { $Text += "`nFRONTEND_PORT=$Port" }
if ($Text -notmatch '(?m)^HOST_FRONTEND_PORT=') { $Text += "`nHOST_FRONTEND_PORT=$Port" }
if ($ResolvedNvidiaApiKey) {
  $Text = Set-EnvValue -Text $Text -Key "NVIDIA_API_KEY" -Value $ResolvedNvidiaApiKey
}
foreach ($Key in $ProviderEnvKeys) {
  $Value = [Environment]::GetEnvironmentVariable($Key)
  if (($Key -eq "EMBEDDING_API_KEY" -or $Key -eq "RAIL_API_KEY") -and -not $Value) { $Value = $ResolvedNvidiaApiKey }
  $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value
}
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
