# Prompt for Azure location if not already set

# Check if AZURE_LOCATION is already set
$currentLocation = $null
try {
    $currentLocation = azd env get-value AZURE_LOCATION 2>$null
    if ($LASTEXITCODE -ne 0) {
        $currentLocation = $null
    }
} catch {
    $currentLocation = $null
}

if ([string]::IsNullOrEmpty($currentLocation)) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    Select Azure Location                       ║" -ForegroundColor Cyan
    Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Recommended regions for Azure Managed Redis:                  ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║    1) westus3     (West US 3)      " -ForegroundColor Cyan -NoNewline
    Write-Host "← Recommended" -ForegroundColor Green -NoNewline
    Write-Host "               ║" -ForegroundColor Cyan
    Write-Host "║    2) eastus      (East US)                                    ║" -ForegroundColor Cyan
    Write-Host "║    3) eastus2     (East US 2)                                  ║" -ForegroundColor Cyan
    Write-Host "║    4) westeurope  (West Europe)                                ║" -ForegroundColor Cyan
    Write-Host "║    5) northeurope (North Europe)                               ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $locationInput = Read-Host "Enter location number [1-5] or region name (default: westus3)"
    
    # Map number to region or use input directly
    $selectedLocation = switch ($locationInput) {
        "1" { "westus3" }
        "2" { "eastus" }
        "3" { "eastus2" }
        "4" { "westeurope" }
        "5" { "northeurope" }
        "" { "westus3" }
        default { $locationInput }
    }
    
    Write-Host ""
    Write-Host "Setting AZURE_LOCATION to: $selectedLocation" -ForegroundColor Green
    azd env set AZURE_LOCATION $selectedLocation
} else {
    Write-Host "Using existing AZURE_LOCATION: $currentLocation" -ForegroundColor Green
}
