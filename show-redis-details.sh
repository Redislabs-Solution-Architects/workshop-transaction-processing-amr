#!/bin/bash
# Show Azure Managed Redis (AMR) connection details for Redis Insight

set -e

echo ""
echo "============================================"
echo "  Azure Managed Redis Connection Details"
echo "============================================"
echo ""

# Check if azd environment is configured
if ! azd env get-values &>/dev/null; then
    echo "❌ Error: No azd environment found."
    echo "   Run 'azd up' first to deploy the workshop."
    exit 1
fi

# Get values from azd environment
REDIS_HOST=$(azd env get-values | grep REDIS_HOST | cut -d'"' -f2)
REDIS_PORT=$(azd env get-values | grep REDIS_PORT | cut -d'=' -f2)
RG_NAME=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'"' -f2)
REDIS_NAME=$(echo $REDIS_HOST | cut -d'.' -f1)

if [ -z "$REDIS_HOST" ]; then
    echo "❌ Error: REDIS_HOST not found in azd environment."
    echo "   Make sure deployment completed successfully."
    exit 1
fi

echo "Use these values in Redis Insight:"
echo ""
echo "  Host:      $REDIS_HOST"
echo "  Port:      ${REDIS_PORT:-10000}"
echo "  Username:  default"
echo "  TLS:       ✅ Required (must be enabled)"
echo ""

# Get access key
echo "  Password:  (fetching...)"
ACCESS_KEY=$(az redisenterprise database list-keys \
    --cluster-name "$REDIS_NAME" \
    --resource-group "$RG_NAME" \
    --query primaryKey -o tsv 2>/dev/null)

if [ -n "$ACCESS_KEY" ]; then
    # Move cursor up and overwrite
    echo -e "\033[1A\033[K  Password:  $ACCESS_KEY"
else
    echo -e "\033[1A\033[K  Password:  ❌ Failed to retrieve (run 'az login' first)"
fi

echo ""
echo "============================================"
echo "  Resource Group"
echo "============================================"
echo ""
echo "  Name:          $RG_NAME"
echo "  Portal:        https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME"
echo ""
echo "============================================"
echo "  Service URLs"
echo "============================================"
echo ""

UI_URL=$(azd env get-values | grep UI_URL | cut -d'"' -f2)
API_URL=$(azd env get-values | grep API_URL | cut -d'"' -f2)
REDIS_INSIGHT_URL=$(azd env get-values | grep REDIS_INSIGHT_URL | cut -d'"' -f2)

echo "  UI:            $UI_URL"
echo "  API:           $API_URL"
echo "  Redis Insight: $REDIS_INSIGHT_URL"
echo ""

# Offer to open Redis Insight
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "============================================"
    read -p "  Open Redis Insight in browser? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$REDIS_INSIGHT_URL"
    fi
fi

echo ""
