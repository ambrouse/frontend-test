$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8091" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia"
New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path (Join-Path $DeployDir "deploy\compose") | Out-Null
} elseif (!(Test-Path (Join-Path $DeployDir ".git"))) {
  git clone --depth 1 --branch $Branch $RepoUrl $DeployDir
} else {
  git -C $DeployDir pull --ff-only
}
$EnvFile = Join-Path $DeployDir "deploy\compose\.env"
New-Item -ItemType Directory -Force -Path (Split-Path $EnvFile) | Out-Null
if (!(Test-Path $EnvFile)) { Copy-Item "$Root\.env.example" $EnvFile }
$Text = Get-Content $EnvFile -Raw
$DefaultText = Get-Content "$Root\.env.example" -Raw
foreach ($Line in ($DefaultText -split "`r?`n")) {
  if ($Line -match '^([A-Za-z_][A-Za-z0-9_]*)=') {
    $Key = $Matches[1]
    if ($Text -notmatch "(?m)^$([regex]::Escape($Key))=") {
      $Text += "`n$Line"
    }
  }
}
$Text = $Text -replace '(?m)^BACKEND_PORT=.*$', "BACKEND_PORT=$Port"
$Text = $Text -replace '(?m)^HOST_BACKEND_PORT=.*$', "HOST_BACKEND_PORT=$Port"
$Text = $Text -replace '(?m)^LLM_MODEL=meta/llama-3\.1-70b-instruct$', "LLM_MODEL=nvidia/llama-3.3-nemotron-super-49b-v1.5"
if ($Text -notmatch '(?m)^HOST_BACKEND_PORT=') { $Text += "`nHOST_BACKEND_PORT=$Port" }
if ($env:NVIDIA_API_KEY) {
  $Text = $Text -replace '(?m)^NVIDIA_API_KEY=.*$', "NVIDIA_API_KEY=$($env:NVIDIA_API_KEY)"
  $Text = $Text -replace '(?m)^EMBEDDING_API_KEY=.*$', "EMBEDDING_API_KEY=$($env:NVIDIA_API_KEY)"
  $Text = $Text -replace '(?m)^RAIL_API_KEY=.*$', "RAIL_API_KEY=$($env:NVIDIA_API_KEY)"
}
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
