# ============================================================================
# Show Azure Managed Redis (AMR) connection details for Redis Insight
# PowerShell version for Windows
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Azure Managed Redis Connection Details" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if azd environment is configured
try {
    $null = azd env get-values 2>$null
} catch {
    Write-Host "Error: No azd environment found." -ForegroundColor Red
    Write-Host "Run 'azd up' first to deploy the workshop."
    exit 1
}

# Get values from azd environment
$envValues = azd env get-values | Out-String
$REDIS_HOST = ($envValues | Select-String 'REDIS_HOST="([^"]+)"').Matches.Groups[1].Value
$REDIS_PORT = ($envValues | Select-String 'REDIS_PORT=(\d+)').Matches.Groups[1].Value
$RG_NAME = ($envValues | Select-String 'AZURE_RESOURCE_GROUP="([^"]+)"').Matches.Groups[1].Value
$REDIS_NAME = $REDIS_HOST.Split('.')[0]

if (-not $REDIS_HOST) {
    Write-Host "Error: REDIS_HOST not found in azd environment." -ForegroundColor Red
    Write-Host "Make sure deployment completed successfully."
    exit 1
}

Write-Host "Use these values in Redis Insight:"
Write-Host ""
Write-Host "  Host:      $REDIS_HOST"
Write-Host "  Port:      $(if ($REDIS_PORT) { $REDIS_PORT } else { '10000' })"
Write-Host "  Username:  default"
Write-Host "  TLS:       Required (must be enabled)" -ForegroundColor Green
Write-Host ""

# Get access key
Write-Host "  Password:  (fetching...)"
try {
    $ACCESS_KEY = az redisenterprise database list-keys `
        --cluster-name $REDIS_NAME `
        --resource-group $RG_NAME `
        --query primaryKey -o tsv 2>$null
    
    if ($ACCESS_KEY) {
        # Move cursor up and overwrite
        $pos = $Host.UI.RawUI.CursorPosition
        $pos.Y -= 1
        $Host.UI.RawUI.CursorPosition = $pos
        Write-Host "  Password:  $ACCESS_KEY                    "
    } else {
        Write-Host "  Password:  Failed to retrieve (run 'az login' first)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Password:  Failed to retrieve (run 'az login' first)" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Resource Group" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Name:          $RG_NAME"
$SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Host "  Portal:        https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Service URLs" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$UI_URL = ($envValues | Select-String 'UI_URL="([^"]+)"').Matches.Groups[1].Value
$API_URL = ($envValues | Select-String 'API_URL="([^"]+)"').Matches.Groups[1].Value
$REDIS_INSIGHT_URL = ($envValues | Select-String 'REDIS_INSIGHT_URL="([^"]+)"').Matches.Groups[1].Value

Write-Host "  UI:            $UI_URL"
Write-Host "  API:           $API_URL"
Write-Host "  Redis Insight: $REDIS_INSIGHT_URL"
Write-Host ""

# Offer to open Redis Insight
Write-Host "============================================" -ForegroundColor Cyan
$response = Read-Host "  Open Redis Insight in browser? [y/N]"
if ($response -eq 'y' -or $response -eq 'Y') {
    Start-Process $REDIS_INSIGHT_URL
}

Write-Host ""
