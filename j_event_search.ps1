param(
    [Parameter(Mandatory=$true)]
    [string]$ExportFolder,
    [Parameter(Mandatory=$true)]
    [string]$EventHandlerName,
    [Parameter(Mandatory=$false)]
    [string]$Server = "dev"
)

Import-Module JAMS

if (Test-Path JD:)
{
    Remove-PSDrive -Name JD -Force
}

New-PSDrive -Name JD JAMS $Server

# Define specific folders to search
$JamsFolders = @("abc", "dbc", "kbc")

# Initialize results array
$allJobs = @()

# Loop through each specified folder
foreach ($folder in $JamsFolders) {
    Write-Host "Searching in folder: $folder" -ForegroundColor Cyan
    
    try {
        # Get all entries from current folder and filter for jobs with event handlers
        $entries = Get-JAMSEntry -Folder $folder
        $jobs = $entries | Where-Object { 
            $_.PSObject.TypeNames -contains "JAMS.Job" -and
            $_.Events -and 
            ($_.Events | Where-Object { $_.Handler -eq $EventHandlerName })
        }
        
        if ($jobs) {
            Write-Host "  Found $($jobs.Count) job(s) in folder '$folder'" -ForegroundColor Green
            $allJobs += $jobs
        } else {
            Write-Host "  No jobs found in folder '$folder'" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  Error accessing folder '$folder': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Display and export results
if ($allJobs.Count -gt 0) {
    Write-Host "`nTotal jobs found using event handler '$EventHandlerName': $($allJobs.Count)" -ForegroundColor Green
    Write-Host "Jobs found:" -ForegroundColor Green
    $allJobs | Select-Object Name, Folder | Sort-Object Folder, Name | Format-Table -AutoSize
    
    # Export to CSV
    $exportPath = Join-Path $ExportFolder "JobsWithEventHandler_$($EventHandlerName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $allJobs | Select-Object Name, Folder | Sort-Object Folder, Name | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Results exported to: $exportPath" -ForegroundColor Yellow
} else {
    Write-Host "`nNo jobs found using event handler '$EventHandlerName' in any of the specified folders" -ForegroundColor Red
}

Write-Host "`nSearch completed." -ForegroundColor Green
