. "$PSScriptRoot\stop.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted AI Virtual Assistant deploy"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)
