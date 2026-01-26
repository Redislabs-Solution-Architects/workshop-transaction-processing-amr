# Pre-provision hook: Set location and pre-create resource group
# This ensures the RG is fully replicated before Bicep deployment starts

$ErrorActionPreference = "Stop"

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
    $currentLocation = $selectedLocation
} else {
    Write-Host "Using existing AZURE_LOCATION: $currentLocation" -ForegroundColor Green
}

# ============================================================================
# PRE-CREATE RESOURCE GROUP
# This ensures the RG is fully replicated across Azure before Bicep runs
# ============================================================================

# Get environment name for resource group naming
$azureEnvName = $null
try {
    $azureEnvName = azd env get-value AZURE_ENV_NAME 2>$null
} catch {
    $azureEnvName = $null
}

if ([string]::IsNullOrEmpty($azureEnvName)) {
    Write-Host "ERROR: AZURE_ENV_NAME not set. Run 'azd env new <name>' first." -ForegroundColor Red
    exit 1
}

$rgName = "rg-$azureEnvName"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              Pre-creating Resource Group                       ║" -ForegroundColor Cyan
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  This ensures Azure has time to replicate the RG globally      ║" -ForegroundColor Cyan
Write-Host "║  before the main deployment starts.                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if RG already exists
$rgExists = $false
try {
    $rgCheck = az group show --name $rgName --query "name" -o tsv 2>$null
    if ($LASTEXITCODE -eq 0 -and $rgCheck) {
        $rgExists = $true
    }
} catch {
    $rgExists = $false
}

if ($rgExists) {
    Write-Host "✓ Resource group '$rgName' already exists" -ForegroundColor Green
} else {
    Write-Host "Creating resource group '$rgName' in '$currentLocation'..." -ForegroundColor Yellow
    az group create `
        --name $rgName `
        --location $currentLocation `
        --tags "azd-env-name=$azureEnvName" `
        --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create resource group" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Resource group created" -ForegroundColor Green
    
    # Wait for replication (10 seconds is usually enough)
    Write-Host "Waiting 10 seconds for Azure global replication..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Verify the RG is accessible
    $provisioningState = az group show --name $rgName --query "properties.provisioningState" -o tsv 2>$null
    if ($provisioningState -eq "Succeeded") {
        Write-Host "✓ Resource group verified and ready" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: Resource group verification unclear, proceeding anyway..." -ForegroundColor Yellow
    }
}

Write-Host ""
