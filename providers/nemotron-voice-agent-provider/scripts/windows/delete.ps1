. "$PSScriptRoot\stop.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted Nemotron Voice Agent deploy"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)
