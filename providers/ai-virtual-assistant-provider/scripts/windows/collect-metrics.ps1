. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId "ai-virtual-assistant-provider"
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13001" }
$ApiPort = $env:API_GATEWAY_PORT; if (-not $ApiPort) { $ApiPort = "9000" }
$Args = @("--env-file",".env","-f","deploy/compose/docker-compose.yaml")
if (Test-Path (Join-Path $DeployDir ".runtime/docker-compose.aihub.yaml")) { $Args += @("-f",".runtime/docker-compose.aihub.yaml") }
if (Test-Path (Join-Path $DeployDir ".runtime/docker-compose.cpu.yaml")) { $Args += @("-f",".runtime/docker-compose.cpu.yaml") }
Write-ProviderMetrics -Root $Root -DeployDir $DeployDir -ComposeArgs $Args -HealthUrl "http://127.0.0.1:$ApiPort/agent/health" -Port ([int]$ApiPort)
