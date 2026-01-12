# ============================================================================
# Sync Modules & Restart Processor
# PowerShell version for Windows
# ============================================================================
# This script uploads your local processor/modules to Azure Files and restarts
# the processor container so your changes take effect.
#
# Usage: .\sync-and-restart.ps1
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Blue
Write-Host "  Workshop Module Sync & Restart" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue

# Check if azd environment exists
try {
    $null = azd env list 2>$null
} catch {
    Write-Host "Error: No azd environment found." -ForegroundColor Red
    Write-Host "Please run 'azd up' first to deploy the workshop."
    exit 1
}

# Get environment variables from azd
Write-Host "`n-> Loading environment configuration..." -ForegroundColor Yellow

$envValues = azd env get-values | Out-String
$STORAGE_ACCOUNT = ($envValues | Select-String 'STORAGE_ACCOUNT_NAME="([^"]+)"').Matches.Groups[1].Value
$SHARE_NAME = ($envValues | Select-String 'STORAGE_SHARE_NAME="([^"]+)"').Matches.Groups[1].Value
$RESOURCE_GROUP = ($envValues | Select-String 'AZURE_RESOURCE_GROUP="([^"]+)"').Matches.Groups[1].Value

if (-not $STORAGE_ACCOUNT -or -not $SHARE_NAME -or -not $RESOURCE_GROUP) {
    Write-Host "Error: Missing environment variables." -ForegroundColor Red
    Write-Host "Required: STORAGE_ACCOUNT_NAME, STORAGE_SHARE_NAME, AZURE_RESOURCE_GROUP"
    Write-Host ""
    Write-Host "Make sure deployment completed successfully with 'azd up'."
    exit 1
}

Write-Host "  Storage Account: " -NoNewline
Write-Host $STORAGE_ACCOUNT -ForegroundColor Green
Write-Host "  File Share: " -NoNewline
Write-Host $SHARE_NAME -ForegroundColor Green
Write-Host "  Resource Group: " -NoNewline
Write-Host $RESOURCE_GROUP -ForegroundColor Green

# Get storage account key
Write-Host "`n-> Getting storage credentials..." -ForegroundColor Yellow
$STORAGE_KEY = az storage account keys list `
    --resource-group $RESOURCE_GROUP `
    --account-name $STORAGE_ACCOUNT `
    --query '[0].value' -o tsv

if (-not $STORAGE_KEY) {
    Write-Host "Error: Could not retrieve storage account key." -ForegroundColor Red
    Write-Host "Make sure you're logged in with 'az login'."
    exit 1
}

# Check if modules directory exists
$MODULES_DIR = "processor\modules"
if (-not (Test-Path $MODULES_DIR)) {
    Write-Host "Error: Directory '$MODULES_DIR' not found." -ForegroundColor Red
    Write-Host "Please run this script from the workshop root directory."
    exit 1
}

# Upload modules to Azure Files
Write-Host "`n-> Uploading modules to Azure Files..." -ForegroundColor Yellow

# Upload __init__.py
$initFile = Join-Path $MODULES_DIR "__init__.py"
if (Test-Path $initFile) {
    az storage file upload `
        --account-name $STORAGE_ACCOUNT `
        --account-key $STORAGE_KEY `
        --share-name $SHARE_NAME `
        --source $initFile `
        --path "__init__.py" `
        --output none 2>$null
}

# Upload all Python files
Get-ChildItem -Path $MODULES_DIR -Filter "*.py" | ForEach-Object {
    Write-Host "  Uploading " -NoNewline
    Write-Host $_.Name -ForegroundColor Green -NoNewline
    Write-Host "..."
    az storage file upload `
        --account-name $STORAGE_ACCOUNT `
        --account-key $STORAGE_KEY `
        --share-name $SHARE_NAME `
        --source $_.FullName `
        --path $_.Name `
        --output none
}

Write-Host "Files uploaded successfully" -ForegroundColor Green

# Restart the processor container
Write-Host "`n-> Restarting processor container..." -ForegroundColor Yellow

$processorRevision = az containerapp revision list `
    --name processor `
    --resource-group $RESOURCE_GROUP `
    --query '[0].name' -o tsv

try {
    az containerapp revision restart `
        --name processor `
        --resource-group $RESOURCE_GROUP `
        --revision $processorRevision `
        --output none 2>$null
} catch {
    az containerapp update `
        --name processor `
        --resource-group $RESOURCE_GROUP `
        --set-env-vars "RESTART_TIMESTAMP=$(Get-Date -UFormat %s)" `
        --output none
}

Write-Host "Processor restarting" -ForegroundColor Green

# Restart the API container
Write-Host "`n-> Restarting API container..." -ForegroundColor Yellow

$apiRevision = az containerapp revision list `
    --name api `
    --resource-group $RESOURCE_GROUP `
    --query '[0].name' -o tsv

try {
    az containerapp revision restart `
        --name api `
        --resource-group $RESOURCE_GROUP `
        --revision $apiRevision `
        --output none 2>$null
} catch {
    az containerapp update `
        --name api `
        --resource-group $RESOURCE_GROUP `
        --set-env-vars "RESTART_TIMESTAMP=$(Get-Date -UFormat %s)" `
        --output none
}

Write-Host "API restarting" -ForegroundColor Green

# Wait for containers to be ready
Write-Host "`n-> Waiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Check container statuses
$PROCESSOR_STATUS = az containerapp show `
    --name processor `
    --resource-group $RESOURCE_GROUP `
    --query 'properties.runningStatus' -o tsv 2>$null

$API_STATUS = az containerapp show `
    --name api `
    --resource-group $RESOURCE_GROUP `
    --query 'properties.runningStatus' -o tsv 2>$null

Write-Host "  Processor status: " -NoNewline
Write-Host $(if ($PROCESSOR_STATUS) { $PROCESSOR_STATUS } else { "Unknown" }) -ForegroundColor Green
Write-Host "  API status: " -NoNewline
Write-Host $(if ($API_STATUS) { $API_STATUS } else { "Unknown" }) -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Sync complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your module changes are now live. Check the UI to see results."

$UI_URL = ($envValues | Select-String 'UI_URL="([^"]+)"').Matches.Groups[1].Value
Write-Host "UI URL: $UI_URL"
Write-Host ""
