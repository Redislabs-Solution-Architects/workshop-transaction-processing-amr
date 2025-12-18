> **Tip:** For best viewing in your IDE, use markdown preview (VS Code: `Cmd+Shift+V` on Mac, `Ctrl+Shift+V` on Windows/Linux)

# Redis Transaction Processing Workshop

Build a real-time transaction backend with Redis. Store data so it can be queiried in a single command and make it AI-searchable with vector embeddings.

## What You'll Learn

- **Redis Streams** — Ingest transactions in real-time
- **Redis Lists** — Retrieve recent transactions in order
- **Redis JSON** — Store and query transaction details
- **Sorted Sets** — Rank spending by category and merchant
- **TimeSeries** — Track spending trends over time
- **Vector Search** — Search transactions by meaning, not keywords

## Get Started

1. Spin up the workshop:
   ```bash
   docker compose up -d
   ```

2. Open the UI http://localhost:3001 and click **Redis Insight** to verify everything is running

3. Head to [`processor/README.md`](processor/README.md) to start completing the modules
