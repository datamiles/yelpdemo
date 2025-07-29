param(
    [Parameter(Mandatory=$true)]
    [string]$ExportFolder,
    [Parameter(Mandatory=$true)]
    [string]$EventHandlerName,
    [Parameter(Mandatory=$false)]
    [string]$ParentFolder = "abc",
    [Parameter(Mandatory=$false)]
    [string]$Server = "dev"
)

Import-Module JAMS

if (Test-Path JD:)
{
    Remove-PSDrive -Name JD -Force
}

New-PSDrive -Name JD JAMS $Server

# Function to recursively search folders
function Search-JAMSFolderRecursive {
    param(
        [string]$FolderPath,
        [string]$EventHandler,
        [int]$Depth = 0
    )
    
    $indent = "  " * $Depth
    Write-Host "$indent Searching folder: $FolderPath" -ForegroundColor Cyan
    
    $folderJobs = @()
    
    try {
        # Get all entries from current folder
        $entries = Get-JAMSEntry -Folder $FolderPath
        
        # Filter for jobs using ElementTypeName and matching event handler
        $jobs = $entries | Where-Object { 
            $_.ElementTypeName -eq "Job" -and
            $_.Events -ne $null -and 
            ($_.Events | Where-Object { $_.Handler -eq $EventHandler })
        }
        
        if ($jobs) {
            Write-Host "$indent   Found $($jobs.Count) job(s) with event handler '$EventHandler'" -ForegroundColor Green
            $folderJobs += $jobs
        }
        
        # Get subfolders using ElementTypeName
        $subfolders = $entries | Where-Object { 
            $_.ElementTypeName -eq "Folder"
        }
        
        foreach ($subfolder in $subfolders) {
            $subfolderPath = if ($FolderPath -eq "\") { 
                "\$($subfolder.Name)" 
            } else { 
                "$FolderPath\$($subfolder.Name)" 
            }
            
            $subfolderJobs = Search-JAMSFolderRecursive -FolderPath $subfolderPath -EventHandler $EventHandler -Depth ($Depth + 1)
            $folderJobs += $subfolderJobs
        }
        
    }
    catch {
        Write-Host "$indent   Error accessing folder '$FolderPath': $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $folderJobs
}

# Start recursive search from parent folder
Write-Host "Starting recursive search from parent folder: $ParentFolder" -ForegroundColor Yellow
Write-Host "Looking for event handler: $EventHandlerName" -ForegroundColor Yellow
Write-Host "=" * 60

$allJobs = Search-JAMSFolderRecursive -FolderPath $ParentFolder -EventHandler $EventHandlerName

# Display and export results
if ($allJobs.Count -gt 0) {
    Write-Host "`n" + "=" * 60
    Write-Host "SEARCH COMPLETE" -ForegroundColor Green
    Write-Host "Total jobs found using event handler '$EventHandlerName': $($allJobs.Count)" -ForegroundColor Green
    Write-Host "`nJobs found:" -ForegroundColor Green
    
    # Create detailed results with full folder path and event details
    $results = $allJobs | Select-Object Name, Folder, ElementTypeName, @{
        Name = 'MatchingEventHandlers'
        Expression = { 
            ($_.Events | Where-Object { $_.Handler -eq $EventHandlerName } | ForEach-Object { $_.Handler }) -join ', '
        }
    }, @{
        Name = 'EventTypes'
        Expression = { 
            ($_.Events | Where-Object { $_.Handler -eq $EventHandlerName } | ForEach-Object { $_.EventType }) -join ', '
        }
    }
    
    $results | Sort-Object Folder, Name | Format-Table -AutoSize
    
    # Export to CSV
    $exportPath = Join-Path $ExportFolder "JobsWithEventHandler_$($EventHandlerName)_Recursive_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $results | Sort-Object Folder, Name | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Results exported to: $exportPath" -ForegroundColor Yellow
    
    # Summary by folder
    Write-Host "`nSummary by folder:" -ForegroundColor Cyan
    $allJobs | Group-Object Folder | Sort-Object Name | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) job(s)" -ForegroundColor White
    }
    
    # Summary by ElementTypeName (should all be "Job")
    Write-Host "`nSummary by Element Type:" -ForegroundColor Cyan
    $allJobs | Group-Object ElementTypeName | Sort-Object Name | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) item(s)" -ForegroundColor White
    }
    
} else {
    Write-Host "`n" + "=" * 60
    Write-Host "No jobs found using event handler '$EventHandlerName' in folder '$ParentFolder' or its subfolders" -ForegroundColor Red
}

Write-Host "`nRecursive search completed." -ForegroundColor Green
