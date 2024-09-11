param(
  [Parameter(Mandatory=$true)]
  [string] $ExportType
)

$scriptFolder = Join-Path (Get-Location).Path "ExportScripts"

switch ($ExportType) {
  "stocks"  { & "$scriptFolder\export_stocks.py" }
  "bonds"   { & "$scriptFolder\export_bonds.py" }
  "oil"     { & "$scriptFolder\export_oil.py" }
  default   { Write-Error "Invalid export type: $ExportType" }
}

.\runexports.ps1 -ExportType stocks
