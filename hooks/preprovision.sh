#!/bin/bash
# Pre-provision hook: Set location and pre-create resource group
# This ensures the RG is fully replicated before Bicep deployment starts

set -e

# Check if AZURE_LOCATION is already set (suppress error for missing key)
CURRENT_LOCATION=""
if azd env get-value AZURE_LOCATION >/dev/null 2>&1; then
    CURRENT_LOCATION=$(azd env get-value AZURE_LOCATION 2>/dev/null)
fi

if [ -z "$CURRENT_LOCATION" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    Select Azure Location                       ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║  Recommended regions for Azure Managed Redis:                  ║"
    echo "║                                                                ║"
    echo "║    1) westus3     (West US 3)      ← Recommended               ║"
    echo "║    2) eastus      (East US)                                    ║"
    echo "║    3) eastus2     (East US 2)                                  ║"
    echo "║    4) westeurope  (West Europe)                                ║"
    echo "║    5) northeurope (North Europe)                               ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    read -p "Enter location number [1-5] or region name (default: westus3): " LOCATION_INPUT

    # Map number to region or use input directly
    case "$LOCATION_INPUT" in
        1|"") SELECTED_LOCATION="westus3" ;;
        2) SELECTED_LOCATION="eastus" ;;
        3) SELECTED_LOCATION="eastus2" ;;
        4) SELECTED_LOCATION="westeurope" ;;
        5) SELECTED_LOCATION="northeurope" ;;
        *) SELECTED_LOCATION="$LOCATION_INPUT" ;;
    esac

    echo ""
    echo "Setting AZURE_LOCATION to: $SELECTED_LOCATION"
    azd env set AZURE_LOCATION "$SELECTED_LOCATION"
    CURRENT_LOCATION="$SELECTED_LOCATION"
else
    echo "Using existing AZURE_LOCATION: $CURRENT_LOCATION"
fi

# ============================================================================
# PRE-CREATE RESOURCE GROUP
# This ensures the RG is fully replicated across Azure before Bicep runs
# ============================================================================

# Get environment name for resource group naming
AZURE_ENV_NAME=$(azd env get-value AZURE_ENV_NAME 2>/dev/null || echo "")
if [ -z "$AZURE_ENV_NAME" ]; then
    echo "ERROR: AZURE_ENV_NAME not set. Run 'azd env new <name>' first."
    exit 1
fi

RG_NAME="rg-${AZURE_ENV_NAME}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Pre-creating Resource Group                       ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  This ensures Azure has time to replicate the RG globally      ║"
echo "║  before the main deployment starts.                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if RG already exists
if az group show --name "$RG_NAME" --query "name" -o tsv 2>/dev/null; then
    echo "✓ Resource group '$RG_NAME' already exists"
else
    echo "Creating resource group '$RG_NAME' in '$CURRENT_LOCATION'..."
    az group create \
        --name "$RG_NAME" \
        --location "$CURRENT_LOCATION" \
        --tags "azd-env-name=$AZURE_ENV_NAME" \
        --output none
    
    echo "✓ Resource group created"
    
    # Wait for replication (10 seconds is usually enough)
    echo "Waiting 10 seconds for Azure global replication..."
    sleep 10
    
    # Verify the RG is accessible
    if az group show --name "$RG_NAME" --query "provisioningState" -o tsv 2>/dev/null | grep -q "Succeeded"; then
        echo "✓ Resource group verified and ready"
    else
        echo "⚠ Warning: Resource group verification unclear, proceeding anyway..."
    fi
fi

echo ""
