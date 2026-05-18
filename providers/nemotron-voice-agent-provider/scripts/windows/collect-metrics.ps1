. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId "nemotron-voice-agent-provider"
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
$Args = @("--env-file",".env","-f","docker-compose.yml")
Write-ProviderMetrics -Root $Root -DeployDir $DeployDir -ComposeArgs $Args -HealthUrl "http://127.0.0.1:$Port" -Port ([int]$Port)
