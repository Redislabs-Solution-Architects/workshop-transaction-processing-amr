#!/bin/bash
# ============================================================================
# Workshop Module Test Script
# 
# Two-phase testing workflow:
#   run:   Implement modules and verify manually
#   reset: Reset everything back to starting state
#
# Usage: 
#   ./test.sh run [modules...]  # Implement modules, wait for verification
#   ./test.sh reset             # Reset all modules to templates
#   ./test.sh status            # Check current status
#
# Examples:
#   ./test.sh run 1       # Implement module 1 only
#   ./test.sh run 1 2     # Implement modules 1 and 2
#   ./test.sh reset       # Reset everything
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/processor/modules"
SOLUTIONS_DIR="$SCRIPT_DIR/processor/solutions"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_phase() { echo -e "${CYAN}[PHASE]${NC} $1"; }

MODULE_FILES=(
    "ordered_transactions.py"    # Module 1 - List
    "store_transaction.py"       # Module 2 - JSON
    "spending_categories.py"     # Module 3 - Sorted Sets
    "spending_over_time.py"      # Module 4 - TimeSeries
    "vector_search.py"           # Module 5 - Vector Search
)

MODULE_NAMES=(
    "Ordered Transactions (List)"
    "Store Transaction (JSON)"
    "Spending Categories (Sorted Sets)"
    "Spending Over Time (TimeSeries)"
    "Vector Search"
)

# Template content for each module (minimal placeholder)
get_template() {
    local module_num=$1
    case $module_num in
        1)
            cat << 'EOF'
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
EOF
            ;;
        2)
            cat << 'EOF'
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
EOF
            ;;
        *)
            echo "Module $module_num template not implemented"
            return 1
            ;;
    esac
}

complete_module() {
    local module_num=$1
    local module_file="${MODULE_FILES[$((module_num-1))]}"
    
    log_info "Completing module $module_num: $module_file"
    cp "$SOLUTIONS_DIR/$module_file" "$MODULES_DIR/$module_file"
    log_success "Module $module_num completed"
}

reset_module() {
    local module_num=$1
    local module_file="${MODULE_FILES[$((module_num-1))]}"
    
    log_info "Resetting module $module_num: $module_file"
    get_template $module_num > "$MODULES_DIR/$module_file"
    log_success "Module $module_num reset to template"
}

reset_all() {
    log_info "Resetting all modules to templates..."
    for i in 1 2; do
        reset_module $i
    done
    log_success "All modules reset"
}

check_status() {
    log_info "Checking API status..."
    curl -s https://api.braveflower-2e8c0c0e.westus3.azurecontainerapps.io/api/status | python3 -m json.tool
}

sync_and_wait() {
    log_info "Syncing to Azure..."
    START_TIME=$(date +%s.%N)
    
    ./sync-and-restart.sh 2>&1
    
    END_TIME=$(date +%s.%N)
    ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
    
    log_success "Sync completed in ${ELAPSED}s"
    
    log_info "Waiting 15 seconds for services to restart..."
    sleep 15
    
    log_info "Verifying status..."
    check_status
}

# ============================================================================
# RUN: Implement modules and wait for manual verification
# ============================================================================
run_modules() {
    local arg="$1"
    local modules=()
    
    # Map run arguments to modules (cumulative - each level includes all previous)
    case "$arg" in
        1|"")
            # run 1 or run (no arg) = Transactions tab (modules 1 + 2)
            modules=(1 2)
            ;;
        3)
            # run 3 = Transactions + Categories (modules 1 + 2 + 3)
            modules=(1 2 3)
            ;;
        4)
            # run 4 = Transactions + Categories + TimeSeries (modules 1 + 2 + 3 + 4)
            modules=(1 2 3 4)
            ;;
        5|all)
            # run 5 or run all = All tabs (modules 1 + 2 + 3 + 4 + 5)
            modules=(1 2 3 4 5)
            ;;
        *)
            log_warn "Unknown argument: $arg"
            echo ""
            echo "Usage: ./test.sh run [1|3|4|5]"
            echo ""
            echo "  run     or  run 1   → Transactions tab (modules 1 + 2)"
            echo "  run 3               → + Categories tab (modules 1-3)"
            echo "  run 4               → + TimeSeries tab (modules 1-4)"
            echo "  run 5               → + Search tab (all modules 1-5)"
            exit 1
            ;;
    esac
    
    echo ""
    echo "========================================"
    log_phase "RUN: Implement & Verify"
    echo "========================================"
    echo ""
    
    # Show what we're implementing
    log_info "Modules to implement:"
    for module_num in "${modules[@]}"; do
        local name="${MODULE_NAMES[$((module_num-1))]}"
        echo "  • Module $module_num: $name"
    done
    echo ""
    
    # Implement each module
    for module_num in "${modules[@]}"; do
        complete_module $module_num
    done
    echo ""
    
    # Sync to Azure
    sync_and_wait
    
    echo ""
    echo "========================================"
    log_success "RUN COMPLETE"
    echo "========================================"
    echo ""
    echo "📋 Manual verification checklist:"
    echo "   1. Open the UI: https://ui.braveflower-2e8c0c0e.westus3.azurecontainerapps.io"
    echo "   2. Click 'Begin Workshop' button"
    echo "   3. Verify the implemented features work correctly"
    echo "   4. Check Redis Insight for data: https://redis-insight.braveflower-2e8c0c0e.westus3.azurecontainerapps.io"
    echo ""
    echo "When done verifying, run:"
    echo "   ${GREEN}./test.sh reset${NC}"
    echo ""
}

# ============================================================================
# RESET: Reset everything back to starting state
# ============================================================================
reset_modules() {
    echo ""
    echo "========================================"
    log_phase "RESET: Back to Start"
    echo "========================================"
    echo ""
    
    # Reset all modules
    reset_all
    echo ""
    
    # Sync to Azure
    sync_and_wait
    
    echo ""
    echo "========================================"
    log_success "RESET COMPLETE"
    echo "========================================"
    echo ""
    echo "✓ All modules reset to template state"
    echo "✓ Workshop is ready for a fresh start"
    echo ""
}

# ============================================================================
# Main
# ============================================================================
case "${1:-}" in
    run)
        shift
        run_modules "$@"
        ;;
    reset)
        reset_modules
        ;;
    status)
        check_status
        ;;
    *)
        echo ""
        echo "Workshop Module Test Script"
        echo "==========================="
        echo ""
        echo "Usage: $0 {run|reset|status} [option]"
        echo ""
        echo "Commands:"
        echo "  run [1|3|4|5|all]  Implement modules by UI tab"
        echo "  reset              Reset all modules back to templates"
        echo "  status             Check current API status"
        echo ""
        echo "Run Options (cumulative - each includes all previous):"
        echo "  run     or  run 1  → Transactions tab (modules 1 + 2)"
        echo "  run 3              → + Categories tab (modules 1-3)"
        echo "  run 4              → + TimeSeries tab (modules 1-4)"
        echo "  run 5              → + Search tab (all modules 1-5)"
        echo ""
        echo "Examples:"
        echo "  $0 run       # Unlock Transactions tab only"
        echo "  $0 run 3     # Unlock Transactions + Categories"
        echo "  $0 run 5     # Unlock all tabs"
        echo "  $0 reset     # Reset everything"
        echo ""
        echo "UI Tabs & Required Modules:"
        echo "  Tab 1: Transactions         → Modules 1 + 2 (List + JSON)"
        echo "  Tab 2: Spending Categories  → Module 3 (Sorted Set)"
        echo "  Tab 3: Spending Over Time   → Module 4 (TimeSeries)"
        echo "  Tab 4: Search               → Module 5 (Vector)"
        echo ""
        exit 1
        ;;
esac
