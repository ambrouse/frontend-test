$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13002" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8091" }
function Get-ComposeEnvValue {
  param(
    [string]$Path,
    [string]$Key,
    [string]$Default
  )
  if (!(Test-Path $Path)) { return $Default }
  $Line = Get-Content -Path $Path | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -Last 1
  if (-not $Line) { return $Default }
  $Value = ($Line -split '=', 2)[1].Trim()
  if ($Value.StartsWith('"') -and $Value.EndsWith('"') -and $Value.Length -ge 2) {
    $Value = $Value.Substring(1, $Value.Length - 2)
  }
  if ($Value) { return $Value }
  return $Default
}
function Invoke-WarehouseCompose {
  param([string[]]$ComposeArgs)
  & docker compose --env-file "deploy/compose/.env" -f "deploy/compose/docker-compose.dev.yaml" @ComposeArgs
}
function Wait-WarehouseHttp {
  param(
    [string]$Url,
    [string]$Name,
    [int]$Retries = 80
  )
  for ($i = 1; $i -le $Retries; $i++) {
    try {
      Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 | Out-Null
      Write-Output "OK: $Name"
      return
    } catch {
      Start-Sleep -Seconds 2
    }
  }
  throw "$Name did not become ready at $Url"
}
function Invoke-WarehouseSql {
  param(
    [string]$Sql,
    [string]$PgUser,
    [string]$PgDb
  )
  $Sql | & docker compose --env-file "deploy/compose/.env" -f "deploy/compose/docker-compose.dev.yaml" exec -T timescaledb psql -v ON_ERROR_STOP=1 -U $PgUser -d $PgDb
  if ($LASTEXITCODE -ne 0) { throw "psql failed with exit code $LASTEXITCODE" }
}
function Ensure-WarehouseDatabase {
  param([string]$BackendPort)
  $EnvFile = "deploy/compose/.env"
  $PgUser = Get-ComposeEnvValue -Path $EnvFile -Key "POSTGRES_USER" -Default "warehouse"
  $PgDb = Get-ComposeEnvValue -Path $EnvFile -Key "POSTGRES_DB" -Default "warehouse"
  $AdminPassword = Get-ComposeEnvValue -Path $EnvFile -Key "DEFAULT_ADMIN_PASSWORD" -Default "changeme"

  Write-Output "Waiting for TimescaleDB..."
  for ($i = 1; $i -le 80; $i++) {
    Invoke-WarehouseCompose -ComposeArgs @("exec", "-T", "timescaledb", "pg_isready", "-U", $PgUser, "-d", $PgDb) *> $null
    if ($LASTEXITCODE -eq 0) { break }
    if ($i -eq 80) { throw "TimescaleDB did not become ready" }
    Start-Sleep -Seconds 2
  }

  Write-Output "Applying database migrations..."
  Invoke-WarehouseSql -Sql "CREATE TABLE IF NOT EXISTS schema_migrations (filename TEXT PRIMARY KEY, applied_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW());" -PgUser $PgUser -PgDb $PgDb
  $Migrations = @(
    "data/postgres/000_schema.sql",
    "data/postgres/001_equipment_schema.sql",
    "data/postgres/002_document_schema.sql",
    "data/postgres/004_inventory_movements_schema.sql",
    "scripts/setup/create_model_tracking_tables.sql"
  )
  foreach ($File in $Migrations) {
    $Applied = (& docker compose --env-file "deploy/compose/.env" -f "deploy/compose/docker-compose.dev.yaml" exec -T timescaledb psql -U $PgUser -d $PgDb -tAc "SELECT 1 FROM schema_migrations WHERE filename='$File'" 2>$null | Out-String).Trim()
    if ($Applied -eq "1") {
      Write-Output "  - skip $File"
      continue
    }
    Write-Output "  - apply $File"
    $SqlPath = Join-Path (Get-Location) ($File -replace '/', '\')
    Invoke-WarehouseSql -Sql (Get-Content -Raw -Path $SqlPath) -PgUser $PgUser -PgDb $PgDb
    Invoke-WarehouseCompose -ComposeArgs @("exec", "-T", "timescaledb", "psql", "-v", "ON_ERROR_STOP=1", "-U", $PgUser, "-d", $PgDb, "-c", "INSERT INTO schema_migrations(filename) VALUES ('$File') ON CONFLICT (filename) DO NOTHING;")
    if ($LASTEXITCODE -ne 0) { throw "failed to record migration $File" }
  }

  Write-Output "Ensuring default users exist..."
  $SeedUsersScript = @'
import asyncio
import os
import asyncpg
import bcrypt

async def main():
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "timescaledb"),
        port=int(os.getenv("DB_PORT", "5432")),
        user=os.getenv("POSTGRES_USER", "warehouse"),
        password=os.getenv("POSTGRES_PASSWORD", "changeme"),
        database=os.getenv("POSTGRES_DB", "warehouse"),
    )

    async def upsert_user(username, email, full_name, role, password_env, default_password):
        password = os.getenv(password_env, default_password).encode("utf-8")
        if len(password) > 72:
            password = password[:72]
        hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode("utf-8")

        exists = await conn.fetchval("SELECT EXISTS(SELECT 1 FROM users WHERE username=$1)", username)
        if exists:
            await conn.execute(
                "UPDATE users SET hashed_password=$1, status='active', updated_at=NOW() WHERE username=$2",
                hashed,
                username,
            )
        else:
            await conn.execute(
                "INSERT INTO users (username, email, full_name, role, status, hashed_password) VALUES ($1,$2,$3,$4,'active',$5)",
                username,
                email,
                full_name,
                role,
                hashed,
            )

    await upsert_user("admin", "admin@warehouse.com", "System Administrator", "admin", "DEFAULT_ADMIN_PASSWORD", "changeme")
    await upsert_user("user", "user@warehouse.com", "Regular User", "operator", "DEFAULT_USER_PASSWORD", "changeme")
    await conn.close()

asyncio.run(main())
print("Default users are ready")
'@
  $SeedUsersScript | & docker compose --env-file "deploy/compose/.env" -f "deploy/compose/docker-compose.dev.yaml" exec -T backend python -
  if ($LASTEXITCODE -ne 0) { throw "default user creation failed" }
  Invoke-WarehouseCompose -ComposeArgs @("exec", "-T", "redis", "redis-cli", "FLUSHDB") *> $null

  Wait-WarehouseHttp -Url "http://localhost:$BackendPort/api/v1/health" -Name "backend health"
  $LoginBody = @{ username = "admin"; password = $AdminPassword } | ConvertTo-Json -Compress
  $Login = Invoke-RestMethod -Method Post -Uri "http://localhost:$BackendPort/api/v1/auth/login" -ContentType "application/json" -Body $LoginBody -TimeoutSec 30
  if (-not $Login.access_token) { throw "auth login smoke check did not return an access token" }
}
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
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
    $env:BACKEND_PORT = $BackendPort
    $env:HOST_BACKEND_PORT = $BackendPort
    $env:FRONTEND_PORT = $Port
    $env:HOST_FRONTEND_PORT = $Port
    docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml up -d --build --wait --wait-timeout 600
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed with exit code $LASTEXITCODE" }
    Ensure-WarehouseDatabase -BackendPort $BackendPort
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
    Pop-Location
  }
}
$Status = @{ projectId=$Id; state="running"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running warehouse stack"; progressPercent=100; health=@{ level="ok"; message="Started" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=[int]$Port } | ConvertTo-Json -Compress)
