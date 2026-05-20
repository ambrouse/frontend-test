$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "web-agent" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$SearxngContainer = $env:AIHUB_SEARXNG_CONTAINER; if (-not $SearxngContainer) { $SearxngContainer = "web-agent-searxng" }

& (Join-Path $Root "scripts\windows\stop.ps1") | Out-Null
$PreviousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try { docker rm -f $SearxngContainer | Out-Null } catch {}
$ErrorActionPreference = $PreviousPreference
Start-Sleep -Seconds 2
Remove-DeployDirSafe -DeployDir $DeployDir
Remove-Item -LiteralPath "$Root\runtime" -Recurse -Force -ErrorAction SilentlyContinue
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)
