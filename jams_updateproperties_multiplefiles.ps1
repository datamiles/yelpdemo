param (
    [string]$folderPath,         # Path to the folder containing XML files
    [string]$action,             # Action to perform: "Add" or "Remove"
    [string]$propertyName,       # Name of the property to add/remove
    [string]$propertyTypeName,   # Type name of the property (required for Add action)
    [string]$propertyValue       # Value of the property (required for Add action)
)

# Check if the folder exists
if (-not (Test-Path $folderPath)) {
    Write-Host "Folder not found: $folderPath"
    exit
}

# Get all XML files in the folder
$xmlFiles = Get-ChildItem -Path $folderPath -Filter "*.xml"

if ($xmlFiles.Count -eq 0) {
    Write-Host "No XML files found in the folder: $folderPath"
    exit
}

foreach ($file in $xmlFiles) {
    Write-Host "Processing file: $($file.FullName)"
    
    # Load the XML file
    $xml = [xml](Get-Content -Path $file.FullName)

    # Navigate to the <properties> node under <job>
    $jobProperties = $xml.JAMSObjects.job.properties
    if (-not $jobProperties) {
        Write-Host "<properties> fragment under <job> not found in file: $($file.FullName). Skipping..."
        continue
    }

    # Perform the requested action
    switch ($action.ToLower()) {
        "add" {
            if (-not $propertyName -or -not $propertyTypeName -or -not $propertyValue) {
                Write-Host "For 'Add' action, you must specify -propertyName, -propertyTypeName, and -propertyValue."
                continue
            }

            # Check if the property already exists
            $existingProperty = $jobProperties.property | Where-Object { $_.name -eq $propertyName }
            if ($existingProperty) {
                Write-Host "Property '$propertyName' already exists in file: $($file.FullName). No changes made."
            } else {
                # Create the new <property> element
                $newProperty = $xml.CreateElement("property")
                $newProperty.SetAttribute("name", $propertyName)
                $newProperty.SetAttribute("typename", $propertyTypeName)
                $newProperty.SetAttribute("value", $propertyValue)

                # Append the new property to the <properties> node
                $jobProperties.AppendChild($newProperty) | Out-Null
                Write-Host "Property '$propertyName' added successfully in file: $($file.FullName)."
            }
        }
        "remove" {
            if (-not $propertyName) {
                Write-Host "For 'Remove' action, you must specify -propertyName."
                continue
            }

            # Check if the property exists
            $existingProperty = $jobProperties.property | Where-Object { $_.name -eq $propertyName }
            if ($existingProperty) {
                # Remove the property
                $jobProperties.RemoveChild($existingProperty) | Out-Null
                Write-Host "Property '$propertyName' removed successfully from file: $($file.FullName)."
            } else {
                Write-Host "Property '$propertyName' not found in file: $($file.FullName). No action taken."
            }
        }
        default {
            Write-Host "Invalid action specified. Use 'Add' or 'Remove'."
            continue
        }
    }

    # Save the updated XML back to the file
    $xml.Save($file.FullName)
    Write-Host "Changes saved to file: $($file.FullName)"
}

Write-Host "Batch processing completed for all XML files in the folder: $folderPath"
