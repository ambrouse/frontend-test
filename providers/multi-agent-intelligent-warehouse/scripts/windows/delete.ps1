& "$PSScriptRoot\stop.ps1"
Write-Output (@{ state="deleted" } | ConvertTo-Json)
