param(
  [Parameter(Mandatory=$true)]
  [string] $ExportType
)

$scriptFolder = Join-Path (Get-Location).Path "ExportScripts"

switch ($ExportType) {
  # Existing logic for stocks, bonds, and oil
  "stocks"  { & "$scriptFolder\export_stocks.py" }
  "bonds"   { & "$scriptFolder\export_bonds.py" }
  "oil"     { & "$scriptFolder\export_oil.py" }

  # Handle cotton export with sub-scripts
  "cotton" {
    $cottonScripts = @("cotton_uk.py", "cotton_us.py", "cotton_pk.py", "cotton_ca.py")
    foreach ($script in $cottonScripts) {
      & "$scriptFolder\$script"
    }
  }

  default   { Write-Error "Invalid export type: $ExportType" }
}

.\runexports.ps1 -ExportType stocks
