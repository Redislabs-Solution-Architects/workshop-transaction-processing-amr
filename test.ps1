# ============================================================================
# Workshop Module Test Script
# PowerShell version for Windows
# ============================================================================
# Two-phase testing workflow:
#   run:   Implement modules and verify manually
#   reset: Reset everything back to starting state
#
# Usage: 
#   .\test.ps1 run [1|3|4|5]  # Implement modules, wait for verification
#   .\test.ps1 reset          # Reset all modules to templates
#   .\test.ps1 status         # Check current status
#
# Examples:
#   .\test.ps1 run            # Implement modules 1 + 2 (default)
#   .\test.ps1 run 3          # Implement modules 1-3
#   .\test.ps1 reset          # Reset everything
# ============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Option
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$MODULES_DIR = Join-Path $SCRIPT_DIR "processor\modules"
$SOLUTIONS_DIR = Join-Path $SCRIPT_DIR "processor\solutions"

$MODULE_FILES = @(
    "ordered_transactions.py",    # Module 1 - List
    "store_transaction.py",       # Module 2 - JSON
    "spending_categories.py",     # Module 3 - Sorted Sets
    "spending_over_time.py",      # Module 4 - TimeSeries
    "vector_search.py"            # Module 5 - Vector Search
)

$MODULE_NAMES = @(
    "Ordered Transactions (List)",
    "Store Transaction (JSON)",
    "Spending Categories (Sorted Sets)",
    "Spending Over Time (TimeSeries)",
    "Vector Search"
)

function Write-Info($message) {
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $message
}

function Write-Success($message) {
    Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
    Write-Host $message
}

function Write-Warn($message) {
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $message
}

function Write-Phase($message) {
    Write-Host "[PHASE] " -ForegroundColor Cyan -NoNewline
    Write-Host $message
}

function Get-Template($moduleNum) {
    switch ($moduleNum) {
        1 {
            return @'
"""
Module 1: Ordered Transactions

Store transactions in a Redis List, ordered from newest to oldest.
This provides a simple timeline of all transactions.
"""

from typing import List, Dict


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Add transaction ID to ordered list (newest first).
    """
    tx_id = tx_data.get('transactionId')

    # TODO: Replace the line below with:
    # Add transaction ID to the beginning of the list "transactions:ordered".
    # This keeps newest transactions at the front (index 0).
    pass


def get_recent_transactions(redis_client, limit: int = 10) -> List[str]:
    """
    Retrieve most recent transactions from list.
    Returns list of transaction IDs, newest first.

    """
    # TODO: Replace the line below with:
    # Get transaction IDs from "transactions:ordered"
    # Get a range of items from the list.
    # Start at 0 (newest), end at limit-1.
    return []
'@
        }
        2 {
            return @'
"""
Module 2: Store Transaction

Store complete transaction as a JSON document in Redis.
This provides the source of truth for all transaction data.
"""

from typing import Dict, List, Optional


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Store transaction as JSON document.
    """
    tx_id = tx_data.get('transactionId')

    transaction = {
        'transactionId': tx_id,
        'customerId': tx_data.get('customerId'),
        'amount': float(tx_data.get('amount', 0)),
        'merchant': tx_data.get('merchant'),
        'category': tx_data.get('category'),
        'timestamp': int(tx_data.get('timestamp', 0)),
        'location': tx_data.get('location'),
        'cardLast4': tx_data.get('cardLast4'),
    }

    # TODO: Replace the line below with:
    # Add JSON to Redis
    # Key format: f"transaction:{tx_id}"
    # Path: "$" (root)
    pass


def get_transaction(redis_client, tx_id: str) -> Optional[Dict]:
    """
    Retrieve a single transaction by ID.
    """
    # TODO: Replace the line below with:
    # Retrieve JSON from Redis
    # Key format: f"transaction:{tx_id}"
    # Path: "$" (root)
    result = None

    return result[0] if result else None

def get_transactions_by_ids(redis_client, tx_ids: List[str]) -> List[Dict]:
    """
    Retrieve multiple transactions by IDs using JSON.MGET.
    Single Redis call for all documents.
    """
    if not tx_ids:
        return []

    keys = [f"transaction:{tx_id}" for tx_id in tx_ids]
    
    # TODO: Replace the line below with:
    # Fetch JSON for the keys defined above, in one call
    # Path: "$" (root)
    results = []

    transactions = []
    for result in results:
        if result and result[0]:
            transactions.append(result[0])

    return transactions
'@
        }
        default {
            return "# Module $moduleNum template not implemented"
        }
    }
}

function Complete-Module($moduleNum) {
    $moduleFile = $MODULE_FILES[$moduleNum - 1]
    Write-Info "Completing module ${moduleNum}: $moduleFile"
    
    $sourcePath = Join-Path $SOLUTIONS_DIR $moduleFile
    $destPath = Join-Path $MODULES_DIR $moduleFile
    
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Success "Module $moduleNum completed"
}

function Reset-Module($moduleNum) {
    $moduleFile = $MODULE_FILES[$moduleNum - 1]
    Write-Info "Resetting module ${moduleNum}: $moduleFile"
    
    $template = Get-Template $moduleNum
    $destPath = Join-Path $MODULES_DIR $moduleFile
    
    $template | Out-File -FilePath $destPath -Encoding utf8 -NoNewline
    Write-Success "Module $moduleNum reset to template"
}

function Reset-AllModules {
    Write-Info "Resetting all modules to templates..."
    for ($i = 1; $i -le 2; $i++) {
        Reset-Module $i
    }
    Write-Success "All modules reset"
}

function Get-ApiStatus {
    Write-Info "Checking API status..."
    try {
        $envValues = azd env get-values | Out-String
        $API_URL = ($envValues | Select-String 'API_URL="([^"]+)"').Matches.Groups[1].Value
        $response = Invoke-RestMethod -Uri "$API_URL/api/status" -Method Get
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Warn "Could not fetch API status: $_"
    }
}

function Sync-AndWait {
    Write-Info "Syncing to Azure..."
    $startTime = Get-Date
    
    $syncScript = Join-Path $SCRIPT_DIR "sync-and-restart.ps1"
    if (Test-Path $syncScript) {
        & $syncScript
    } else {
        # Fall back to bash script if running in Git Bash on Windows
        $bashScript = Join-Path $SCRIPT_DIR "sync-and-restart.sh"
        & bash $bashScript
    }
    
    $elapsed = (Get-Date) - $startTime
    Write-Success "Sync completed in $($elapsed.TotalSeconds.ToString('F1'))s"
    
    Write-Info "Waiting 15 seconds for services to restart..."
    Start-Sleep -Seconds 15
    
    Write-Info "Verifying status..."
    Get-ApiStatus
}

function Run-Modules($arg) {
    $modules = @()
    
    # Map run arguments to modules (cumulative)
    switch ($arg) {
        { $_ -eq "1" -or $_ -eq "" -or $null -eq $_ } {
            # run 1 or run (no arg) = Transactions tab (modules 1 + 2)
            $modules = @(1, 2)
        }
        "3" {
            # run 3 = Transactions + Categories (modules 1 + 2 + 3)
            $modules = @(1, 2, 3)
        }
        "4" {
            # run 4 = Transactions + Categories + TimeSeries (modules 1 + 2 + 3 + 4)
            $modules = @(1, 2, 3, 4)
        }
        { $_ -eq "5" -or $_ -eq "all" } {
            # run 5 or run all = All tabs (modules 1 + 2 + 3 + 4 + 5)
            $modules = @(1, 2, 3, 4, 5)
        }
        default {
            Write-Warn "Unknown argument: $arg"
            Write-Host ""
            Write-Host "Usage: .\test.ps1 run [1|3|4|5]"
            Write-Host ""
            Write-Host "  run     or  run 1   -> Transactions tab (modules 1 + 2)"
            Write-Host "  run 3               -> + Categories tab (modules 1-3)"
            Write-Host "  run 4               -> + TimeSeries tab (modules 1-4)"
            Write-Host "  run 5               -> + Search tab (all modules 1-5)"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Phase "RUN: Implement & Verify"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Info "Modules to implement:"
    foreach ($moduleNum in $modules) {
        $name = $MODULE_NAMES[$moduleNum - 1]
        Write-Host "  * Module ${moduleNum}: $name"
    }
    Write-Host ""
    
    # Implement each module
    foreach ($moduleNum in $modules) {
        Complete-Module $moduleNum
    }
    Write-Host ""
    
    # Sync to Azure
    Sync-AndWait
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Success "RUN COMPLETE"
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "When done verifying, run:"
    Write-Host "   .\test.ps1 reset" -ForegroundColor Green
    Write-Host ""
    
    # Show Redis connection details and URLs
    $showRedisScript = Join-Path $SCRIPT_DIR "show-redis-details.ps1"
    if (Test-Path $showRedisScript) {
        & $showRedisScript
    }
}

function Reset-Modules {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Phase "RESET: Back to Start"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Reset-AllModules
    Write-Host ""
    
    # Sync to Azure
    Sync-AndWait
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Success "RESET COMPLETE"
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All modules reset to template state"
    Write-Host "Workshop is ready for a fresh start"
    Write-Host ""
}

function Show-Usage {
    Write-Host ""
    Write-Host "Workshop Module Test Script"
    Write-Host "==========================="
    Write-Host ""
    Write-Host "Usage: .\test.ps1 {run|reset|status} [option]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  run [1|3|4|5]  Implement modules by UI tab"
    Write-Host "  reset          Reset all modules back to templates"
    Write-Host "  status         Check current API status"
    Write-Host ""
    Write-Host "Run Options (cumulative - each includes all previous):"
    Write-Host "  run     or  run 1  -> Transactions tab (modules 1 + 2)"
    Write-Host "  run 3              -> + Categories tab (modules 1-3)"
    Write-Host "  run 4              -> + TimeSeries tab (modules 1-4)"
    Write-Host "  run 5              -> + Search tab (all modules 1-5)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\test.ps1 run       # Unlock Transactions tab only"
    Write-Host "  .\test.ps1 run 3     # Unlock Transactions + Categories"
    Write-Host "  .\test.ps1 run 5     # Unlock all tabs"
    Write-Host "  .\test.ps1 reset     # Reset everything"
    Write-Host ""
    Write-Host "UI Tabs & Required Modules:"
    Write-Host "  Tab 1: Transactions         -> Modules 1 + 2 (List + JSON)"
    Write-Host "  Tab 2: Spending Categories  -> Module 3 (Sorted Set)"
    Write-Host "  Tab 3: Spending Over Time   -> Module 4 (TimeSeries)"
    Write-Host "  Tab 4: Search               -> Module 5 (Vector)"
    Write-Host ""
}

# Main
switch ($Command) {
    "run" {
        Run-Modules $Option
    }
    "reset" {
        Reset-Modules
    }
    "status" {
        Get-ApiStatus
    }
    default {
        Show-Usage
        exit 1
    }
}
