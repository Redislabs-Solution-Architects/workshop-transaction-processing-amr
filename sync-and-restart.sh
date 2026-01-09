#!/bin/bash
# ============================================================================
# Sync Modules & Restart Processor
# ============================================================================
# This script uploads your local processor/modules to Azure Files and restarts
# the processor container so your changes take effect.
#
# Usage: ./sync-and-restart.sh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Workshop Module Sync & Restart${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if azd environment exists
if ! azd env list &>/dev/null; then
    echo -e "${RED}Error: No azd environment found.${NC}"
    echo "Please run 'azd up' first to deploy the workshop."
    exit 1
fi

# Get environment variables from azd
echo -e "\n${YELLOW}→ Loading environment configuration...${NC}"

STORAGE_ACCOUNT=$(azd env get-value STORAGE_ACCOUNT_NAME 2>/dev/null || true)
SHARE_NAME=$(azd env get-value STORAGE_SHARE_NAME 2>/dev/null || true)
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP 2>/dev/null || true)

if [[ -z "$STORAGE_ACCOUNT" || -z "$SHARE_NAME" || -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}Error: Missing environment variables.${NC}"
    echo "Required: STORAGE_ACCOUNT_NAME, STORAGE_SHARE_NAME, AZURE_RESOURCE_GROUP"
    echo ""
    echo "Make sure deployment completed successfully with 'azd up'."
    exit 1
fi

echo -e "  Storage Account: ${GREEN}$STORAGE_ACCOUNT${NC}"
echo -e "  File Share: ${GREEN}$SHARE_NAME${NC}"
echo -e "  Resource Group: ${GREEN}$RESOURCE_GROUP${NC}"

# Get storage account key
echo -e "\n${YELLOW}→ Getting storage credentials...${NC}"
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query '[0].value' -o tsv)

if [[ -z "$STORAGE_KEY" ]]; then
    echo -e "${RED}Error: Could not retrieve storage account key.${NC}"
    echo "Make sure you're logged in with 'az login'."
    exit 1
fi

# Check if modules directory exists
MODULES_DIR="processor/modules"
if [[ ! -d "$MODULES_DIR" ]]; then
    echo -e "${RED}Error: Directory '$MODULES_DIR' not found.${NC}"
    echo "Please run this script from the workshop root directory."
    exit 1
fi

# Upload modules to Azure Files
echo -e "\n${YELLOW}→ Uploading modules to Azure Files...${NC}"

# Create __init__.py in share if it doesn't exist
az storage file upload \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$STORAGE_KEY" \
    --share-name "$SHARE_NAME" \
    --source "$MODULES_DIR/__init__.py" \
    --path "__init__.py" \
    --output none 2>/dev/null || true

# Upload all Python files
for file in "$MODULES_DIR"/*.py; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        echo -e "  Uploading ${GREEN}$filename${NC}..."
        az storage file upload \
            --account-name "$STORAGE_ACCOUNT" \
            --account-key "$STORAGE_KEY" \
            --share-name "$SHARE_NAME" \
            --source "$file" \
            --path "$filename" \
            --output none
    fi
done

echo -e "${GREEN}✓ Files uploaded successfully${NC}"

# Restart the processor container
echo -e "\n${YELLOW}→ Restarting processor container...${NC}"

# Get the current revision and restart by creating a new revision
az containerapp revision restart \
    --name processor \
    --resource-group "$RESOURCE_GROUP" \
    --revision "$(az containerapp revision list \
        --name processor \
        --resource-group "$RESOURCE_GROUP" \
        --query '[0].name' -o tsv)" \
    --output none 2>/dev/null || \
az containerapp update \
    --name processor \
    --resource-group "$RESOURCE_GROUP" \
    --set-env-vars "RESTART_TIMESTAMP=$(date +%s)" \
    --output none

echo -e "${GREEN}✓ Processor restarting${NC}"

# Restart the API container (also uses modules)
echo -e "\n${YELLOW}→ Restarting API container...${NC}"

az containerapp revision restart \
    --name api \
    --resource-group "$RESOURCE_GROUP" \
    --revision "$(az containerapp revision list \
        --name api \
        --resource-group "$RESOURCE_GROUP" \
        --query '[0].name' -o tsv)" \
    --output none 2>/dev/null || \
az containerapp update \
    --name api \
    --resource-group "$RESOURCE_GROUP" \
    --set-env-vars "RESTART_TIMESTAMP=$(date +%s)" \
    --output none

echo -e "${GREEN}✓ API restarting${NC}"

# Wait for containers to be ready
echo -e "\n${YELLOW}→ Waiting for containers to be ready...${NC}"
sleep 8

# Check container statuses
PROCESSOR_STATUS=$(az containerapp show \
    --name processor \
    --resource-group "$RESOURCE_GROUP" \
    --query 'properties.runningStatus' -o tsv 2>/dev/null || echo "Unknown")
    
API_STATUS=$(az containerapp show \
    --name api \
    --resource-group "$RESOURCE_GROUP" \
    --query 'properties.runningStatus' -o tsv 2>/dev/null || echo "Unknown")

echo -e "  Processor status: ${GREEN}$PROCESSOR_STATUS${NC}"
echo -e "  API status: ${GREEN}$API_STATUS${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Sync complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Your module changes are now live. Check the UI to see results."
echo -e "UI URL: $(azd env get-value UI_URL 2>/dev/null || echo 'Run azd env get-values to see URLs')"
echo ""
