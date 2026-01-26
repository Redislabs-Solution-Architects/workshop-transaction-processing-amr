> **Tip:** For best viewing in your IDE, use markdown preview (VS Code: `Cmd+Shift+V` on Mac, `Ctrl+Shift+V` on Windows/Linux)

# Redis Transaction Processing Workshop

Build a real-time transaction backend with Azure Managed Redis. Store data so it can be queried in a single command and make it AI-searchable with vector embeddings.

## Prerequisites

Before starting, ensure you have the required software installed:
- **[Prerequisites Guide](docs/PREREQUISITES.md)** — All required software and installation instructions

## What You'll Learn

- **Redis Streams** — Ingest transactions in real-time
- **Redis Lists** — Retrieve recent transactions in order
- **Redis JSON** — Store and query transaction details
- **Sorted Sets** — Rank spending by category and merchant
- **TimeSeries** — Track spending trends over time
- **Vector Search** — Search transactions by meaning, not keywords

## Get Started

### Option A: GitHub Codespaces (Recommended)

The fastest way to start — no local installation required!

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Redislabs-Solution-Architects/workshop-transaction-processing)

1. Click the button above (or go to **Code → Codespaces → Create**)
2. Wait ~2 minutes for the container to build
3. Login to Azure:
   ```bash
   azd auth login
   az login --use-device-code
   ```
4. Deploy:
   ```bash
   azd up
   ```
   > **Note:** If deployment fails with `ParentResourceNotFound`, run `azd provision && azd deploy` to complete. This is a known ARM race condition.

Everything is pre-installed: `azd`, `az`, `python`, `pwsh`.

---

### Option B: Local Development

#### Step 1: Login to Azure

```bash
azd auth login
az login
```

#### Step 2: Deploy to Azure

```bash
azd up
```

You'll be prompted for:

| Prompt | What to Enter | Example |
|--------|--------------|---------|
| **Environment name** | A unique name for your deployment (lowercase, no spaces) | `john-workshop` |
| **Azure subscription** | Select from your available subscriptions (use arrow keys) | `My Subscription` |

> **Note:** Resources deploy to `westus3` by default (best Azure Managed Redis availability).
> To use a different region: `azd env set AZURE_LOCATION eastus && azd up`

> **⚠️ Known Issue: ARM Race Condition**
> 
> Azure Managed Redis v2 API may report `ParentResourceNotFound` during first deployment even though resources are created successfully. This is an ARM timing issue.
> 
> **If deployment fails:**
> - Run `azd provision && azd deploy` to complete
> - The resources are usually already deployed — the error is cosmetic
>
> **Typical deployment time:** 15-25 minutes (first run may fail and require a second `azd provision`)

> **Tip:** The environment name is used for:
> - Resource group: `rg-<name>` (e.g., `rg-john-workshop`)
> - azd environment reference (for managing multiple deployments)
> 
> Other resources get auto-generated names with a unique hash (e.g., `redis-abc123xyz`).

First deployment takes **15-25 minutes**. Grab a coffee! ☕

### Step 3: Access Your Application

After deployment, you'll see URLs like:
```
UI URL:         https://ui.xxx.azurecontainerapps.io
API URL:        https://api.xxx.azurecontainerapps.io
Redis Insight:  https://redis-insight.xxx.azurecontainerapps.io
```

Open the **UI URL** to start the workshop!

---

## Deploy Your Code Changes

After editing any module file, deploy in ~10 seconds:

```bash
./sync-and-restart.sh
```

This uploads your `processor/modules/*.py` to Azure and restarts the processor.

---

## Workshop Modules

| Module | Topic | Type |
|--------|-------|------|
| **[Module 0](docs/MODULE_0_PORTAL.md)** | Explore Your Deployment | Portal Walkthrough |
| **[Module 1-5](processor/README.md)** | Build the Transaction Processor | Hands-on Coding |
| **[Module 6](docs/MODULE_6_OBSERVABILITY.md)** | Observability with AMR | Portal Walkthrough |

Start with **Module 0** to understand what was deployed, then head to the coding modules.

---

## Clean Up

When done, delete all Azure resources:

```bash
azd down
```

📚 **More Documentation**:
- [Prerequisites](docs/PREREQUISITES.md) — Required software
- [Azure Deployment](docs/AZURE_DEPLOYMENT.md) — Full deployment guide & troubleshooting

