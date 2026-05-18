. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) {
  Push-Location $DeployDir
  try {
    $Args = @("--env-file",".env","-f","deploy/compose/docker-compose.yaml")
    if (Test-Path ".runtime/docker-compose.aihub.yaml") { $Args += @("-f",".runtime/docker-compose.aihub.yaml") }
    if (Test-Path ".runtime/docker-compose.cpu.yaml") { $Args += @("-f",".runtime/docker-compose.cpu.yaml") }
    if ($env:USE_LOCAL_NIM -eq "true") { docker compose @Args --profile local-nim down } else { docker compose @Args down }
  } finally { Pop-Location }
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "stopped" -Port ([int]$Port) -Step "Stopped AI Virtual Assistant stack"
Write-Output (@{ state="stopped"; port=[int]$Port } | ConvertTo-Json -Compress)
