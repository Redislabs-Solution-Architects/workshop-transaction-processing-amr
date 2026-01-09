# Azure Deployment Guide

This guide walks you through deploying the Transaction Processing Workshop to Azure using the Azure Developer CLI (azd).

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)** - [Install azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Docker** - Required for building container images (Docker Desktop, Colima, or Rancher Desktop)
4. **Azure Subscription** - With permissions to create resources

## Quick Start

### Step 1: Login to Azure

```bash
azd auth login
az login
```

### Step 2: Deploy

```bash
azd up
```

You'll be prompted for:
- **Environment name**: Your unique identifier (e.g., `john-workshop`)
- **Azure location**: Region to deploy (e.g., `westus3`)
- **Azure subscription**: Select your subscription

### Step 3: Wait for Deployment

First deployment takes **15-25 minutes**:

| Phase | Duration | What's Happening |
|-------|----------|------------------|
| **Package** | ~5 min | Building Docker images |
| **Provision** | ~10 min | Creating Azure resources |
| **Deploy** | ~2 min | Deploying containers |

### Step 4: Access Your Application

After deployment, you'll see URLs like:

```
UI URL:         https://ui.xxx.azurecontainerapps.io
API URL:        https://api.xxx.azurecontainerapps.io
Redis Insight:  https://redis-insight.xxx.azurecontainerapps.io
```

---

## Development Workflow

### Deploy Code Changes (~10 seconds)

After editing `processor/modules/*.py`:

```bash
./sync-and-restart.sh
```

This:
1. Uploads your local files to Azure Files
2. Restarts the processor container
3. Shows you the UI URL

**No Docker rebuild required!**

### Full Rebuild (only if needed)

If you change files outside `processor/modules/` (like `consumer.py`):

```bash
azd deploy
```

---

## Deployment Timing Reference

### First Deployment (`azd up`)

| Stage | Resource | Time |
|-------|----------|------|
| **Package** | API image | ~2 min |
| | Generator image | ~1 min |
| | Processor image | ~3 min |
| | UI image | ~30 sec |
| **Provision** | Resource Group | ~3 sec |
| | Container Registry | ~11 sec |
| | Virtual Network | ~6 sec |
| | Log Analytics | ~27 sec |
| | Storage Account | ~25 sec |
| | Private Endpoints | ~2 min |
| | Container Apps Environment | ~3-4 min |
| | Azure Managed Redis | ~4-5 min |
| | Container Apps (5) | ~2 min |
| **Total** | | **~15-25 min** |

### Subsequent Deployments

| Command | Time | Use Case |
|---------|------|----------|
| `./sync-and-restart.sh` | ~10 sec | Module changes only |
| `azd deploy` | ~2 min | Full code changes |
| `azd provision` | ~5 min | Infrastructure changes |

---

## What Gets Deployed

The deployment creates:
- Azure Managed Redis (Balanced B3 with RediSearch, RedisJSON, RedisTimeSeries, RedisBloom)
- Azure Container Registry (Premium SKU)
- Virtual Network with private endpoints
- 5 Container Apps (Generator, Processor, API, UI, Redis Insight)
- Log Analytics Workspace

### Step 4: Access Your Application

After deployment completes, URLs are displayed and saved to your environment.

#### Option 1: View URLs from Environment

```bash
# Show all service URLs
azd env get-values | grep -E "UI_URL|API_URL|REDIS_INSIGHT_URL"
```

Example output:
```
API_URL="https://api.ambitiouspond-8eba84fe.westus3.azurecontainerapps.io"
REDIS_INSIGHT_URL="https://redis-insight.ambitiouspond-8eba84fe.westus3.azurecontainerapps.io"
UI_URL="https://ui.ambitiouspond-8eba84fe.westus3.azurecontainerapps.io"
```

#### Option 2: Open URLs Directly

```bash
# Open UI in browser (macOS)
open $(azd env get-values | grep UI_URL | cut -d'"' -f2)

# Open Redis Insight in browser (macOS)
open $(azd env get-values | grep REDIS_INSIGHT_URL | cut -d'"' -f2)
```

#### Option 3: View All Environment Values

```bash
# Show everything (URLs, Redis host, resource group, etc.)
azd env get-values
```

### Step 5: Configure Redis Insight

Redis Insight is deployed inside the same VNet as Azure Managed Redis (AMR), so it can connect via the private endpoint.

**Important**: Azure Managed Redis uses **private endpoints only** - there is no public access. Redis Insight runs inside the VNet and can connect to AMR.

#### Adding the AMR Database

1. Open the Redis Insight URL from the deployment output
2. Click **"+ Add Redis database"**
3. Select **"Add Database Manually"**
4. Fill in the connection details:

| Field | Value | Notes |
|-------|-------|-------|
| **Host** | `redis-xxx.westus3.redis.azure.net` | From `azd env get-values` |
| **Port** | `10000` | AMR uses port 10000 (not 6379) |
| **Database Alias** | `AMR Workshop` | Any name you prefer |
| **Username** | `default` | Required for AMR |
| **Password** | Access key | See below |
| **Use TLS** | ✅ Enabled | **Required** - AMR enforces TLS |

5. Expand **"TLS Settings"** and check:
   - ✅ **Use TLS** must be enabled
   - Leave certificate fields empty (AMR uses public CA)

6. Click **"Add Redis Database"**

#### Getting Connection Details

```bash
# Get host and port from azd
azd env get-values | grep -E "REDIS_HOST|REDIS_PORT"

# Get the access key
az redisenterprise database list-keys \
  --cluster-name $(azd env get-values | grep REDIS_HOST | cut -d'"' -f2 | cut -d'.' -f1) \
  --resource-group $(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'"' -f2)
```

Or copy-paste friendly (shows all details at once):

```bash
echo "=== AMR Connection Details ===" && \
echo "Host:     $(azd env get-values | grep REDIS_HOST | cut -d'\"' -f2)" && \
echo "Port:     10000" && \
echo "Username: default" && \
echo "TLS:      Required" && \
echo "" && \
echo "Access Key:" && \
az redisenterprise database list-keys \
  --cluster-name $(azd env get-values | grep REDIS_HOST | cut -d'"' -f2 | cut -d'.' -f1) \
  --resource-group $(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'"' -f2) \
  --query primaryKey -o tsv
```

#### AMR vs Standard Redis Differences

| Setting | Local Docker | Azure Managed Redis |
|---------|--------------|---------------------|
| Port | 6379 | **10000** |
| Username | (none) | **`default`** |
| Password | (none) | Access key required |
| TLS | Optional | **Required** |
| Access | Direct | Private endpoint only |

#### Why No Public Access?

Azure Managed Redis in this workshop uses **private endpoints** for security:
- Redis is only accessible from within the VNet
- Container Apps (Generator, Processor, API) connect via private DNS
- Redis Insight connects via the same private endpoint
- Your laptop **cannot** directly connect to Redis

If you need to connect from your local machine for debugging, you would need to:
1. Set up a VPN/ExpressRoute to the VNet, or
2. Use Azure Bastion with a jump box, or
3. Temporarily enable public network access (not recommended for production)

## Managing Your Deployment

### View Logs

```bash
# View all service logs
azd monitor --live

# View specific service logs
az containerapp logs show -n api -g <resource-group> --follow
```

### Redeploy After Code Changes

```bash
# Rebuild and redeploy all services
azd deploy

# Redeploy specific service
azd deploy --service api
```

### Update Infrastructure

```bash
# Preview infrastructure changes
azd provision --preview

# Apply infrastructure changes
azd provision
```

### Clean Up Resources

```bash
# Delete all Azure resources
azd down

# Force delete (skip confirmation)
azd down --force
```

## Troubleshooting

### Container App Not Starting

Check the logs:
```bash
az containerapp logs show -n <app-name> -g <resource-group> --follow
```

### Redis Connection Issues

1. Verify the Redis host and port are correct
2. Ensure TLS is enabled (`REDIS_SSL=true`)
3. Check that the password is correct
4. Verify the private endpoint is properly configured

### ACR Pull Errors

```bash
# Verify managed identity has AcrPull role
az role assignment list --assignee <identity-principal-id>
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Azure Subscription                   │
├─────────────────────────────────────────────────────────────┤
│  Resource Group: rg-<your-env-name>                         │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Virtual Network (10.0.0.0/16)              ││
│  │  ┌──────────────────────┐ ┌───────────────────────────┐││
│  │  │ Container Apps Subnet│ │ Private Endpoints Subnet  │││
│  │  │    (10.0.0.0/23)    │ │      (10.0.2.0/24)        │││
│  │  │                      │ │                           │││
│  │  │ ┌────────────────┐   │ │  ┌─────────────────────┐  │││
│  │  │ │  Container     │   │ │  │ Redis PE            │  │││
│  │  │ │  Apps Env      │◄──┼─┼──│ (Enterprise)        │  │││
│  │  │ │                │   │ │  └─────────────────────┘  │││
│  │  │ │ - Generator    │   │ │                           │││
│  │  │ │ - Processor    │   │ │  ┌─────────────────────┐  │││
│  │  │ │ - API          │   │ │  │ ACR PE              │  │││
│  │  │ │ - UI           │◄──┼─┼──│ (Premium)           │  │││
│  │  │ │ - Redis Insight│   │ │  └─────────────────────┘  │││
│  │  │ └────────────────┘   │ │                           │││
│  │  └──────────────────────┘ └───────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Cost Estimate

| Resource | SKU | ~Cost/Hour |
|----------|-----|------------|
| Azure Managed Redis | Balanced B3 (3GB) | ~$0.37 |
| Container Registry | Premium | ~$0.07 |
| Container Apps | Consumption (5 apps) | ~$0.05 |
| Log Analytics | Pay-per-GB | ~$0.01 |
| **Total** | | **~$0.50/hour** |

**Remember to run `azd down` when done to avoid unnecessary charges!**

## Workshop Exercises

With your environment deployed, you can now:

1. **View the UI**: Open the UI URL to see the banking dashboard
2. **Explore Redis Insight**: Connect to see Redis data structures
3. **Complete the workshop modules**: Edit files in `processor/modules/` to implement features
4. **Sync and test**: Run `./sync-and-restart.sh` to deploy your changes

### Development Workflow on Azure

Azure uses Azure Files for code storage, allowing quick syncs without rebuilding images. The workflow is:

1. **Edit locally**: Modify files in `processor/modules/*.py`
2. **Sync and restart**: Run the sync script to upload and restart
3. **Check results**: View the UI to see your changes

```bash
# After editing processor/modules/*.py
./sync-and-restart.sh

# What this does:
# 1. Uploads your local files to Azure Files (~2 seconds)
# 2. Restarts the processor container (~10-15 seconds)
# 3. Shows you the UI URL to verify results
```

### Alternative: Full Rebuild (Slower)

If you need to make changes beyond the modules (e.g., consumer.py), use a full rebuild:

```bash
# Rebuild and push the image
ACR_NAME=$(azd env get-value ACR_NAME)
az acr login --name $ACR_NAME
docker build -t $ACR_NAME.azurecr.io/processor:latest -f processor/Dockerfile .
docker push $ACR_NAME.azurecr.io/processor:latest

# Restart the container
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
az containerapp update -n processor -g $RESOURCE_GROUP --image $ACR_NAME.azurecr.io/processor:latest
