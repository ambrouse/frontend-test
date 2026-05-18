. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) {
  Push-Location $DeployDir
  try {
    docker compose --env-file .env -f docker-compose.yml down
  } finally { Pop-Location }
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "stopped" -Port ([int]$Port) -Step "Stopped Nemotron Voice Agent"
Write-Output (@{ state="stopped"; port=[int]$Port } | ConvertTo-Json -Compress)
