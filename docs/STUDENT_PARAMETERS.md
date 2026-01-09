# Student Configuration Guide

This document explains how to deploy and use the Transaction Processing Workshop on Azure.

---

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

### Step 3: Access Your Application

After deployment (~15-20 minutes), you'll see URLs for:
- **UI**: The banking dashboard
- **API**: REST API endpoint
- **Redis Insight**: Data visualization tool

---

## Deploying Code Changes

After editing files in `processor/modules/`:

```bash
./sync-and-restart.sh
```

This syncs your code to Azure and restarts the processor in ~10 seconds.

---

## Parameter Reference

### Environment Name

| Attribute | Value |
|-----------|-------|
| **Required** | Yes |
| **Format** | Lowercase letters, numbers, hyphens |
| **Max Length** | 20 characters |
| **Example** | `john`, `student01`, `team5-workshop` |

**Why it matters**: This becomes part of your Azure resource names, making them unique and identifiable.

---

### Azure Location

| Attribute | Value |
|-----------|-------|
| **Required** | Yes |
| **Format** | Azure region name |
| **Recommended** | `westus3` |

**Recommended regions**:

| Region | Location | Notes |
|--------|----------|-------|
| `westus3` | Arizona, USA | Recommended |
| `eastus` | Virginia, USA | Alternative US |
| `westeurope` | Netherlands | For EMEA |
| `eastasia` | Hong Kong | For APAC |

---

## Deployment Commands

### Initial Deployment

```bash
# 1. Login to Azure
azd auth login

# 2. Deploy to Azure (~15-20 minutes)
azd up
```

### After Making Code Changes

```bash
# Sync your modules and restart processor (~10 seconds)
./sync-and-restart.sh
```

### View Deployment URLs

```bash
azd env get-values
```

### Clean Up (IMPORTANT!)

```bash
# Delete all Azure resources when done
azd down
```

⚠️ **Don't forget to clean up** - Azure Managed Redis costs ~$0.50/hour even when idle!

---

## Troubleshooting

### "Invalid subscription" Error

Verify your subscription:
```bash
az account list -o table
```

### "Location not available" Error

The region might not support all required services. Try `westus3` or `eastus`.

### "Name already exists" Error

Another student might be using the same environment name. Try a more unique name.

### Resources Created with Wrong Name

Delete and redeploy:
```bash
azd down --force
azd up
```
