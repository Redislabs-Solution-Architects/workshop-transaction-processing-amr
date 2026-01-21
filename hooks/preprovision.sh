#!/bin/bash
# Prompt for Azure location if not already set

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
else
    echo "Using existing AZURE_LOCATION: $CURRENT_LOCATION"
fi
