param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\temp"
)

Import-Module JAMS
New-PSDrive -Name JD JAMS devserver

$jobs = get-ChildItem "JD:\abc\ff" -ObjectType job -FullObject -Recurse -IgnorePredefined

# Define output file path
$outputFile = Join-Path $OutputPath "JobsWithRunawayElement_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force
}

# Clear the file if it exists and add header
if (Test-Path $outputFile) { Remove-Item $outputFile }
"Jobs with Runaway Elements - Generated on $(Get-Date)" | Add-Content -Path $outputFile
"Searched in: JD:\abc\ff" | Add-Content -Path $outputFile
"=" * 60 | Add-Content -Path $outputFile

# Counter for results
$foundCount = 0

Foreach($j in $jobs) { 
    foreach ($e in $j.Elements) { 
        if ($e.ElementTypeName -eq "Runaway") {
            $outputLine = "Job $($j.JobName) in folder $($j.QualifiedFolderName) has a Runaway Element."
            $outputLine | Add-Content -Path $outputFile
            Write-Host $outputLine -ForegroundColor Green  # Also display on screen
            $foundCount++
        }
    }
}

# Add summary to file
"" | Add-Content -Path $outputFile
"=" * 60 | Add-Content -Path $outputFile
"Total jobs with Runaway elements found: $foundCount" | Add-Content -Path $outputFile

Write-Host "`nSearch completed. Found $foundCount jobs with Runaway elements" -ForegroundColor Cyan
Write-Host "Output written to: $outputFile" -ForegroundColor Yellow
