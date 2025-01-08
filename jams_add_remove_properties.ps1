param (
    [string]$xmlFilePath,        # Path to the XML file
    [string]$action,             # Action to perform: "Add" or "Remove"
    [string]$propertyName,       # Name of the property to add/remove
    [string]$propertyTypeName,   # Type name of the property (required for Add action)
    [string]$propertyValue       # Value of the property (required for Add action)
)

# Check if the file exists
if (-not (Test-Path $xmlFilePath)) {
    Write-Host "File not found: $xmlFilePath"
    exit
}

# Load the XML file
$xml = [xml](Get-Content -Path $xmlFilePath)

# Navigate to the <properties> node under <job>
$jobProperties = $xml.JAMSObjects.job.properties
if (-not $jobProperties) {
    Write-Host "<properties> fragment under <job> not found."
    exit
}

# Perform the requested action
switch ($action.ToLower()) {
    "add" {
        if (-not $propertyName -or -not $propertyTypeName -or -not $propertyValue) {
            Write-Host "For 'Add' action, you must specify -propertyName, -propertyTypeName, and -propertyValue."
            exit
        }

        # Check if the property already exists
        $existingProperty = $jobProperties.property | Where-Object { $_.name -eq $propertyName }
        if ($existingProperty) {
            Write-Host "Property '$propertyName' already exists. No changes made."
        } else {
            # Create the new <property> element
            $newProperty = $xml.CreateElement("property")
            $newProperty.SetAttribute("name", $propertyName)
            $newProperty.SetAttribute("typename", $propertyTypeName)
            $newProperty.SetAttribute("value", $propertyValue)

            # Append the new property to the <properties> node
            $jobProperties.AppendChild($newProperty) | Out-Null
            Write-Host "Property '$propertyName' added successfully."
        }
    }
    "remove" {
        if (-not $propertyName) {
            Write-Host "For 'Remove' action, you must specify -propertyName."
            exit
        }

        # Check if the property exists
        $existingProperty = $jobProperties.property | Where-Object { $_.name -eq $propertyName }
        if ($existingProperty) {
            # Remove the property
            $jobProperties.RemoveChild($existingProperty) | Out-Null
            Write-Host "Property '$propertyName' removed successfully."
        } else {
            Write-Host "Property '$propertyName' not found. No action taken."
        }
    }
    default {
        Write-Host "Invalid action specified. Use 'Add' or 'Remove'."
        exit
    }
}

# Save the updated XML back to the file
$xml.Save($xmlFilePath)
Write-Host "Changes saved to: $xmlFilePath"
