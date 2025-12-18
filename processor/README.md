> **Tip:** For best viewing in your IDE, use markdown preview (VS Code: `Cmd+Shift+V` on Mac, `Ctrl+Shift+V` on Windows/Linux)

# Processor Modules

You're building a real-time transaction processor. Transactions stream in every few seconds.

Store them using Redis data structures so each query is instant — no filtering, no sorting at query time.

The [`consumer.py`](consumer.py) reads from the Redis Stream and calls your modules. **You just complete the TODOs.**

---

## Module 1: Ordered Transactions

**Goal:** How can we natively return the last 20 transactions?

**Redis Solution:** Lists — [Docs](https://redis.io/docs/latest/develop/data-types/lists/)

**File:** [`modules/ordered_transactions.py`](modules/ordered_transactions.py)

**Stuck?** [`solutions/ordered_transactions.py`](solutions/ordered_transactions.py)

*Complete Module 2 before restarting — the Transactions tab needs both.*

---

## Module 2: Store Transaction

**Goal:** How can we natively return the details for each transaction?

**Redis Solution:** JSON — [Docs](https://redis.io/docs/latest/develop/data-types/json/)

**File:** [`modules/store_transaction.py`](modules/store_transaction.py)

**Stuck?** [`solutions/store_transaction.py`](solutions/store_transaction.py)

```bash
docker compose restart processor    # Unlocks: Transactions tab on UI (http://localhost:3001)
```

---

## Module 3: Spending Categories

**Goal:** How can we natively return the top spending categories and merchants?

**Redis Solution:** Sorted Sets — [Docs](https://redis.io/docs/latest/develop/data-types/sorted-sets/)

**File:** [`modules/spending_categories.py`](modules/spending_categories.py)

**Stuck?** [`solutions/spending_categories.py`](solutions/spending_categories.py)

```bash
docker compose restart processor    # Unlocks: Categories tab on UI (http://localhost:3001)
```

---

## Module 4: Spending Over Time

**Goal:** How can we natively return spending analytics over a period of time?

**Redis Solution:** TimeSeries — [Docs](https://redis.io/docs/latest/develop/data-types/timeseries/)

**File:** [`modules/spending_over_time.py`](modules/spending_over_time.py)

**Stuck?** [`solutions/spending_over_time.py`](solutions/spending_over_time.py)

```bash
docker compose restart processor    # Unlocks: Spending Chart on UI (http://localhost:3001)
```

---

## Module 5: Vector Search

**Goal:** How can we natively return transactions from a natural language input?

**Redis Solution:** Vector Search + RedisVL — [Vector Search Docs](https://redis.io/docs/latest/develop/ai/search-and-query/query/vector-search/) | [RedisVL Docs](https://docs.redisvl.com/)

**File:** [`modules/vector_search.py`](modules/vector_search.py)

**Stuck?** [`solutions/vector_search.py`](solutions/vector_search.py)

```bash
docker compose restart processor    # Unlocks: Transaction Search on UI (http://localhost:3001)
```

*Note: Embeddings only apply to new transactions after restart.*

---
