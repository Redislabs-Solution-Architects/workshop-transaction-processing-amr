# Processor Modules

You're building the backend for a banking app. Transactions stream in every few seconds.

Store them using Redis data structures so each query is instant — no filtering, no sorting at query time.

The [`consumer.py`](consumer.py) reads from the Redis Stream and calls your modules. **You just complete the TODOs.**

---

## Module 1: Ordered Transactions

> **Redis List** — Store transaction IDs in order for instant retrieval

**Goal:** "Show me my last 20 transactions"

**File:** [`modules/ordered_transactions.py`](modules/ordered_transactions.py)
**Solution:** [`solutions/ordered_transactions.py`](solutions/ordered_transactions.py)

*Complete Module 2 before restarting — the Transactions tab needs both.*

---

## Module 2: Store Transaction

> **Redis JSON** — Store full transaction objects as JSON documents

**Goal:** "Show me the details of this transaction"

**File:** [`modules/store_transaction.py`](modules/store_transaction.py)
**Solution:** [`solutions/store_transaction.py`](solutions/store_transaction.py)

```bash
docker compose restart processor    # Unlocks: Transactions tab on UI (http://localhost:3001)
```

---

## Module 3: Spending Categories

> **Sorted Set** — Track spending by category with automatic sorting

**Goal:** "Where am I spending the most?"

**File:** [`modules/spending_categories.py`](modules/spending_categories.py)
**Solution:** [`solutions/spending_categories.py`](solutions/spending_categories.py)

```bash
docker compose restart processor    # Unlocks: Categories tab on UI (http://localhost:3001)
```

---

## Module 4: Spending Over Time

> **TimeSeries** — Store timestamped data for time-range queries

**Goal:** "How has my spending changed this week?"

**File:** [`modules/spending_over_time.py`](modules/spending_over_time.py)
**Solution:** [`solutions/spending_over_time.py`](solutions/spending_over_time.py)

```bash
docker compose restart processor    # Unlocks: Spending Chart on UI (http://localhost:3001 )
```

---

## Module 5: Vector Search

> **RedisVL** — Semantic search using embeddings and vector similarity

**Goal:** "Find transactions at coffee shops"

**File:** [`modules/vector_search.py`](modules/vector_search.py)
**Solution:** [`solutions/vector_search.py`](solutions/vector_search.py)

**Implement:**
- Schema attrs (dims, distance_metric, algorithm, datatype)
- JSON.SET to store embeddings
- VectorQuery to search

```bash
docker compose restart processor    # Unlocks: Transaction Search on UI (http://localhost:3001 )
```

*Note: Embeddings only apply to new transactions after restart.*

---
