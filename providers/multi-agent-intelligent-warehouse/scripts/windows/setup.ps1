$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8091" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia"
function Get-LocalNvidiaApiKey {
  param([string]$ProviderRoot)
  try {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProviderRoot "..\.."))
    $LocalEnvFile = Join-Path $RepoRoot ".env.local"
    if (!(Test-Path $LocalEnvFile)) { return "" }
    $Line = Get-Content -Path $LocalEnvFile | Where-Object { $_ -match '^\s*NVIDIA_API_KEY\s*=' } | Select-Object -Last 1
    if (-not $Line) { return "" }
    $Value = ($Line -split '=', 2)[1].Trim()
    if ($Value.StartsWith('"') -and $Value.EndsWith('"') -and $Value.Length -ge 2) {
      $Value = $Value.Substring(1, $Value.Length - 2)
    }
    return $Value
  } catch {
    return ""
  }
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
if (-not $ResolvedNvidiaApiKey) {
  $ResolvedNvidiaApiKey = Get-LocalNvidiaApiKey -ProviderRoot $Root
  if ($ResolvedNvidiaApiKey) { $env:NVIDIA_API_KEY = $ResolvedNvidiaApiKey }
}
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
  $Text = $Text -replace '(?m)^NVIDIA_API_KEY=.*$', "NVIDIA_API_KEY=$ResolvedNvidiaApiKey"
  $Text = $Text -replace '(?m)^EMBEDDING_API_KEY=.*$', "EMBEDDING_API_KEY=$ResolvedNvidiaApiKey"
  $Text = $Text -replace '(?m)^RAIL_API_KEY=.*$', "RAIL_API_KEY=$ResolvedNvidiaApiKey"
}
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
