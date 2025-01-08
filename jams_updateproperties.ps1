param (
    [string]$xmlFilePath,        # Path to the XML file
    [string]$propertyName,       # Name of the property to add
    [string]$propertyTypeName,   # Type name of the property
    [string]$propertyValue       # Value of the property
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
    Write-Host "<properties> fragment under <job> not found. Creating it..."
    $jobProperties = $xml.CreateElement("properties")
    $xml.JAMSObjects.job.AppendChild($jobProperties) | Out-Null
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

# Save the updated XML back to the file
$xml.Save($xmlFilePath)
Write-Host "Changes saved to: $xmlFilePath"
