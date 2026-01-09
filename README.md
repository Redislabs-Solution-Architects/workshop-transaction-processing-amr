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

### Step 1: Login to Azure

```bash
azd auth login
az login
```

### Step 2: Deploy to Azure

```bash
azd up
```

You'll be prompted for:
- **Environment name**: Your unique identifier (e.g., `john-workshop`)
- **Azure location**: Region to deploy (e.g., `westus3`)
- **Azure subscription**: Select your subscription

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

Head to [`processor/README.md`](processor/README.md) to start completing the modules.

---

## Clean Up

When done, delete all Azure resources:

```bash
azd down
```

📚 **More Documentation**:
- [Prerequisites](docs/PREREQUISITES.md) — Required software
- [Azure Deployment](docs/AZURE_DEPLOYMENT.md) — Full deployment guide & troubleshooting

