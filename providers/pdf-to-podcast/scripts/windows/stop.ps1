$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "7860" }

function Find-Bash {
  foreach ($Candidate in @("C:\Program Files\Git\bin\bash.exe", "C:\Program Files\Git\usr\bin\bash.exe", "bash")) {
    try { return (Get-Command $Candidate -ErrorAction Stop).Source } catch {}
  }
  throw "Git Bash or bash is required"
}

function Invoke-BashScript {
  param(
    [Parameter(Mandatory = $true)][string]$Bash,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$LogName
  )
  $OutPath = Join-Path $Root "logs\$LogName.out.log"
  $ErrPath = Join-Path $Root "logs\$LogName.err.log"
  Remove-Item -LiteralPath $OutPath, $ErrPath -ErrorAction SilentlyContinue
  $Process = Start-Process `
    -FilePath $Bash `
    -ArgumentList $Arguments `
    -WorkingDirectory $WorkingDirectory `
    -RedirectStandardOutput $OutPath `
    -RedirectStandardError $ErrPath `
    -WindowStyle Hidden `
    -Wait `
    -PassThru

  if (Test-Path $OutPath) { Get-Content -LiteralPath $OutPath }
  if (Test-Path $ErrPath) { Get-Content -LiteralPath $ErrPath }
  if ($Process.ExitCode -ne 0) {
    throw "bash $($Arguments -join ' ') failed with exit code $($Process.ExitCode)"
  }
}

New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ((Test-Path $DeployDir) -and (Test-Path (Join-Path $DeployDir "setup.sh"))) {
  $Bash = Find-Bash
  Invoke-BashScript -Bash $Bash -WorkingDirectory $DeployDir -Arguments @("setup.sh", "--down") -LogName "setup-down"
}
$Status = @{ projectId=$Id; state="stopped"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Stopped"; progressPercent=100; health=@{ level="ok"; message="Stopped" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="stopped"; port=[int]$Port } | ConvertTo-Json -Compress)
