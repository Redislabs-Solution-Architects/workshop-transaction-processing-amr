# Redis Banking Workshop

Build a real-time transaction processing system using Redis Stack.

## What You'll Learn

- **Redis Streams** - Real-time message processing
- **Redis Lists** - Ordered data storage
- **Redis JSON** - Document storage
- **Sorted Sets** - Ranked aggregations
- **TimeSeries** - Time-based analytics

## Quick Start

```bash
docker compose up -d
```

Open http://localhost:3001 to see the UI.

## How It Works

```
Generator → Redis Stream → Processor → Your Modules → UI
```

1. Transactions stream in every 5 seconds
2. You complete 4 modules in `processor/modules/`
3. Each module unlocks a UI feature

## Next Steps

Head to [`processor/README.md`](processor/README.md) to start the workshop.

