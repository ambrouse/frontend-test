. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "ai-virtual-assistant-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13001" }
if (Test-Path -LiteralPath (Join-Path $DeployDir "deploy\compose\docker-compose.yaml")) {
  $Args = @("--env-file", ".env", "-f", "deploy/compose/docker-compose.yaml")
  if (Test-Path -LiteralPath (Join-Path $DeployDir ".runtime\docker-compose.aihub.yaml")) { $Args += @("-f", ".runtime/docker-compose.aihub.yaml") }
  if (Test-Path -LiteralPath (Join-Path $DeployDir ".runtime\docker-compose.cpu.yaml")) { $Args += @("-f", ".runtime/docker-compose.cpu.yaml") }
  Invoke-DockerComposeCleanup -WorkingDirectory $DeployDir -ComposeArgs $Args
}
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted AI Virtual Assistant deploy and local Docker resources"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)
