$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-"
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
function Update-DeploySource {
  param([string]$DeployPath)
  $McpClient = Join-Path $DeployPath "src\ui\hooks\useMCPClient.ts"
  if (!(Test-Path -LiteralPath $McpClient)) { return }
  $Text = Get-Content -LiteralPath $McpClient -Raw
  $Updated = $Text.Replace(
    "AbortSignal.timeout(65000), // 65s timeout for search agent (can take 20-30s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run search agent calls"
  ).Replace(
    "AbortSignal.timeout(65000), // 65s timeout for ARAG agent (takes ~25s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run agent calls"
  )
  if ($Updated -ne $Text) {
    Set-Content -LiteralPath $McpClient -Value $Updated -Encoding utf8
  }
}
New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
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
Update-DeploySource -DeployPath $DeployDir
$EnvFile = Join-Path $DeployDir ".env"
if (!(Test-Path $EnvFile)) { Copy-Item "$Root\.env.example" $EnvFile }
$Text = Get-Content $EnvFile -Raw
$Text = $Text -replace '(?m)^HTTP_HOST_PORT=.*$', "HTTP_HOST_PORT=$Port"
$ResolvedNvidiaApiKey = $env:NVIDIA_API_KEY
if (-not $ResolvedNvidiaApiKey) {
  $ResolvedNvidiaApiKey = Get-LocalNvidiaApiKey -ProviderRoot $Root
  if ($ResolvedNvidiaApiKey) { $env:NVIDIA_API_KEY = $ResolvedNvidiaApiKey }
}
if ($ResolvedNvidiaApiKey) {
  if ($Text -match '(?m)^NVIDIA_API_KEY=.*$') {
    $Text = $Text -replace '(?m)^NVIDIA_API_KEY=.*$', "NVIDIA_API_KEY=$ResolvedNvidiaApiKey"
  } else {
    $Text += "`nNVIDIA_API_KEY=$ResolvedNvidiaApiKey"
  }
  if ($Text -match '(?m)^NGC_API_KEY=.*$') {
    $Text = $Text -replace '(?m)^NGC_API_KEY=.*$', "NGC_API_KEY=$ResolvedNvidiaApiKey"
  } else {
    $Text += "`nNGC_API_KEY=$ResolvedNvidiaApiKey"
  }
}
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
