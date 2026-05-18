. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
if ((Test-Path -LiteralPath (Join-Path $DeployDir ".env")) -and (Test-Path -LiteralPath (Join-Path $DeployDir "docker-compose.yml"))) {
  Invoke-DockerComposeCleanup -WorkingDirectory $DeployDir -ComposeArgs @("--env-file", ".env", "-f", "docker-compose.yml")
}
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted Nemotron Voice Agent deploy and local Docker resources"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)
