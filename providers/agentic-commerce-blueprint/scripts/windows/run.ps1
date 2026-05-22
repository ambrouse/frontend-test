$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
function Assert-DockerDaemon {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI is not installed. Install Docker Desktop, start it, then run this provider again."
  }
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $DockerInfo = & cmd.exe /d /c 'docker info --format "{{.ServerVersion}}" 2>&1'
    if ($LASTEXITCODE -ne 0) {
      $Message = ($DockerInfo | Out-String).Trim()
      if (-not $Message) { $Message = "Docker daemon is not reachable." }
      Write-Output "Docker daemon is not running or not reachable. Start Docker Desktop and wait for the Linux engine, then run this provider again. Docker said: $Message"
      exit 1
    }
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }
}
if ($env:AIHUB_DRY_RUN -ne "1") {
  Assert-DockerDaemon
  if (!(Test-Path $DeployDir)) {
    $SetupScript = Join-Path $Root "scripts\windows\setup.ps1"
    if (!(Test-Path $SetupScript)) { throw "deploy directory missing and setup script is unavailable" }
    & $SetupScript
    if ($LASTEXITCODE -ne 0) { throw "setup failed while preparing deploy directory" }
  }
  Push-Location $DeployDir
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $EnvFile = Join-Path $DeployDir ".env"
    if (Test-Path -LiteralPath $EnvFile) {
      Get-Content -LiteralPath $EnvFile | ForEach-Object {
        if ($_ -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$") {
          $Key = $Matches[1]
          $Value = $Matches[2].Trim('"', "'")
          if ($Value) { Set-Item -Path "Env:$Key" -Value $Value }
        }
      }
    }
    $env:HTTP_HOST_PORT = $Port
    docker compose -f docker-compose.infra.yml -f docker-compose.yml build promotion-agent
    if ($LASTEXITCODE -ne 0) { throw "docker compose build promotion-agent failed with exit code $LASTEXITCODE" }
    docker compose -f docker-compose.infra.yml -f docker-compose.yml up -d --force-recreate
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed with exit code $LASTEXITCODE" }
    $HealthUrl = "http://127.0.0.1:$Port/api/health"
    $Ready = $false
    for ($i = 0; $i -lt 300; $i++) {
      try {
        $Response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 2 -UseBasicParsing
        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300) {
          $Ready = $true
          break
        }
      } catch {
      }
      Start-Sleep -Seconds 2
    }
    if (-not $Ready) { throw "gateway health check did not become ready at $HealthUrl within timeout" }
    $SeederReady = $false
    for ($attempt = 1; $attempt -le 5; $attempt++) {
      docker compose -f docker-compose.infra.yml -f docker-compose.yml --profile seed run --rm milvus-seeder
      if ($LASTEXITCODE -eq 0) {
        $SeederReady = $true
        break
      }
      Start-Sleep -Seconds (10 * $attempt)
    }
    if (-not $SeederReady) { Write-Warning "milvus seeder failed after retries; continuing because the commerce stack is running" }
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
    Pop-Location
  }
}
$Status = @{ projectId=$Id; state="running"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running commerce stack"; progressPercent=100; health=@{ level="ok"; message="Started" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=[int]$Port } | ConvertTo-Json -Compress)
