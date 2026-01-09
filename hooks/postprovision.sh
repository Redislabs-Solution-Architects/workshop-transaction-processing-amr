#!/bin/bash
# ============================================================================
# Post-Provision Hook: Initialize Workshop Modules
# ============================================================================
# This script runs after 'azd provision' to upload the initial module
# templates to Azure Files, so the processor has something to start with.
# ============================================================================

set -e

echo "========================================"
echo "  Initializing Workshop Modules"
echo "========================================"

# Get environment variables from azd
STORAGE_ACCOUNT="${STORAGE_ACCOUNT_NAME:-}"
SHARE_NAME="${STORAGE_SHARE_NAME:-}"
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"

if [[ -z "$STORAGE_ACCOUNT" || -z "$SHARE_NAME" || -z "$RESOURCE_GROUP" ]]; then
    echo "Warning: Storage variables not set. Skipping module initialization."
    echo "This is expected if storage deployment is still in progress."
    exit 0
fi

echo "Storage Account: $STORAGE_ACCOUNT"
echo "File Share: $SHARE_NAME"
echo "Resource Group: $RESOURCE_GROUP"

# Get storage account key
echo ""
echo "→ Getting storage credentials..."
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query '[0].value' -o tsv 2>/dev/null || true)

if [[ -z "$STORAGE_KEY" ]]; then
    echo "Warning: Could not retrieve storage key. Storage may still be provisioning."
    echo "Run './sync-and-restart.sh' manually after deployment completes."
    exit 0
fi

# Check if modules directory exists
MODULES_DIR="processor/modules"
if [[ ! -d "$MODULES_DIR" ]]; then
    echo "Warning: Directory '$MODULES_DIR' not found."
    echo "Running from: $(pwd)"
    exit 0
fi

# Upload initial modules to Azure Files
echo ""
echo "→ Uploading initial module templates..."

for file in "$MODULES_DIR"/*.py; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        echo "  Uploading $filename..."
        az storage file upload \
            --account-name "$STORAGE_ACCOUNT" \
            --account-key "$STORAGE_KEY" \
            --share-name "$SHARE_NAME" \
            --source "$file" \
            --path "$filename" \
            --output none 2>/dev/null || echo "  Warning: Failed to upload $filename"
    fi
done

echo ""
echo "✓ Module initialization complete"
echo ""
echo "Students can now edit processor/modules/*.py locally"
echo "and run './sync-and-restart.sh' to deploy changes."
echo "========================================"
