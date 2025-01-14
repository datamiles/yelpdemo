param (
    [string]$jamsServer,  # JAMS server name
    [string]$folderPath = "\abc\bbb"  # Folder path to retrieve job histories from
)

# Import the JAMS PowerShell module
if (-not (Get-Module -Name JAMS -ListAvailable)) {
    Write-Host "JAMS PowerShell module not found. Please install it before running the script."
    exit
}
Import-Module JAMS

# Connect to the JAMS server
try {
    Write-Host "Connecting to JAMS server: $jamsServer"
    New-PSDrive -Name JD -PSProvider JAMS -Root "\\$jamsServer\JAMS" | Out-Null
    Write-Host "Connected to JAMS server."
} catch {
    Write-Host "Failed to connect to JAMS server: $jamsServer. Ensure the server is reachable."
    exit
}

# Retrieve all jobs in the specified folder
try {
    $jobFolderPath = "JD:\Jobs$folderPath"
    $jobs = Get-ChildItem -Path $jobFolderPath -Recurse -ErrorAction Stop

    if (-not $jobs) {
        Write-Host "No jobs found under the folder: $folderPath"
        exit
    }

    # Loop through each job and retrieve its history
    foreach ($job in $jobs) {
        Write-Host "Retrieving history for job: $($job.Name)"

        $history = Get-JAMSHistory -JobName $job.Name -ErrorAction Stop | Select-Object -Property Batch, Queue, Agent, RunTime, Status

        if ($history) {
            Write-Host "History for job: $($job.Name)"
            $history | ForEach-Object {
                Write-Host "Batch: $($_.Batch), Queue: $($_.Queue), Agent: $($_.Agent), RunTime: $($_.RunTime), Status: $($_.Status)"
            }
        } else {
            Write-Host "No history found for job: $($job.Name)"
        }
    }
} catch {
    Write-Host "An error occurred while retrieving job histories."
    Write-Host $_.Exception.Message
}

# Disconnect from the JAMS server
try {
    Remove-PSDrive -Name JD
    Write-Host "Disconnected from JAMS server."
} catch {
    Write-Host "Failed to disconnect from JAMS server."
}
