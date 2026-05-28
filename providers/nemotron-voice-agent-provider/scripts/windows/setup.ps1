. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "6921" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
Sync-Repo -RepoUrl "https://github.com/mionm/nemotron-voice-agent-provider.git" -Branch $Branch -DeployDir $DeployDir
if ($env:AIHUB_DRY_RUN -ne "1") {
  Copy-EnvIfMissing -Source (Join-Path $DeployDir "config\env.example") -Target (Join-Path $DeployDir ".env")
  $EnvFile = Join-Path $DeployDir ".env"
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  $NvidiaKey = $env:NVIDIA_API_KEY
  if (-not $env:NGC_API_KEY -and $NvidiaKey) { $env:NGC_API_KEY = $NvidiaKey }
  $Text = Set-EnvValue -Text $Text -Key "UI_PORT" -Value $Port
  if (-not [Environment]::GetEnvironmentVariable("TRANSPORT")) { $Text = Set-EnvValue -Text $Text -Key "TRANSPORT" -Value "WEBSOCKET" }
  if (-not [Environment]::GetEnvironmentVariable("ASR_SERVER_URL")) { $Text = Set-EnvValue -Text $Text -Key "ASR_SERVER_URL" -Value "grpc.nvcf.nvidia.com:443" }
  if (-not [Environment]::GetEnvironmentVariable("TTS_SERVER_URL")) { $Text = Set-EnvValue -Text $Text -Key "TTS_SERVER_URL" -Value "grpc.nvcf.nvidia.com:443" }
  if (-not [Environment]::GetEnvironmentVariable("NVIDIA_LLM_URL")) { $Text = Set-EnvValue -Text $Text -Key "NVIDIA_LLM_URL" -Value "https://integrate.api.nvidia.com/v1" }
  if (-not [Environment]::GetEnvironmentVariable("NVIDIA_LLM_MODEL")) { $Text = Set-EnvValue -Text $Text -Key "NVIDIA_LLM_MODEL" -Value "nvidia/nemotron-3-nano-30b-a3b" }
  foreach ($Key in @("NVIDIA_API_KEY","NGC_API_KEY","TRANSPORT","ASR_SERVER_URL","TTS_SERVER_URL","NVIDIA_LLM_URL","NVIDIA_LLM_MODEL","NEMOTRON_PIPELINE_PORT","PYTHON_APP_PORT","TTS_GRPC_PORT","ASR_GRPC_PORT","LLM_HTTP_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if ($Key -eq "NGC_API_KEY" -and -not $Value) { $Value = $NvidiaKey }
    if ($Key -eq "NEMOTRON_PIPELINE_PORT" -and $Value) {
      $Text = Set-EnvValue -Text $Text -Key "PYTHON_APP_PORT" -Value $Value
      continue
    }
    if ($Value) { $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value }
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
  @'
services:
  python-app:
    depends_on: []
    environment:
      - ASR_SERVER_URL=${ASR_SERVER_URL:-grpc.nvcf.nvidia.com:443}
      - TTS_SERVER_URL=${TTS_SERVER_URL:-grpc.nvcf.nvidia.com:443}
      - NVIDIA_LLM_URL=${NVIDIA_LLM_URL:-https://integrate.api.nvidia.com/v1}
      - NVIDIA_API_KEY=${NVIDIA_API_KEY}
  ui-app:
    depends_on:
      python-app:
        condition: service_healthy
'@ | Set-Content -LiteralPath (Join-Path $DeployDir ".aihub-hosted.compose.yml") -Encoding utf8
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "installed" -Port ([int]$Port) -Step "Installed Nemotron Voice Agent source"
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)
