# Processor Modules

## The Scenario

You're building the backend for a banking app. Transactions are streaming in and you need to:

1. Show customers their recent transactions
2. Let them click a transaction to see details
3. Display spending breakdown by category
4. Visualize spending trends over time

Each module you complete powers a different feature in the UI.

---

## How It Works

The [`consumer.py`](consumer.py) reads transactions from a Redis Stream and passes each one to your modules. You don't need to modify it, just complete the TODOs in each module.

```
Redis Stream → consumer.py → Your 4 Modules → UI Unlocks
```

---

## Your Modules

### Module 1: Ordered Transactions
[`modules/ordered_transactions.py`](modules/ordered_transactions.py) — **Unlocks:** Transactions list

*"Show me my last 20 transactions"* — Store transaction IDs in a **Redis List** to maintain order without sorting.

> Got stuck? [`solutions/ordered_transactions.py`](solutions/ordered_transactions.py)

---

### Module 2: Store Transaction
[`modules/store_transaction.py`](modules/store_transaction.py) — **Unlocks:** Transaction details

*"Show me the details of this transaction"* — Store full transaction data as **Redis JSON** documents for instant retrieval.

> Got stuck? [`solutions/store_transaction.py`](solutions/store_transaction.py)

---

### Module 3: Spending Categories
[`modules/spending_categories.py`](modules/spending_categories.py) — **Unlocks:** Categories tab

*"Where am I spending the most?"* — Use **Sorted Sets** to track running totals by category and merchant, always sorted.

> Got stuck? [`solutions/spending_categories.py`](solutions/spending_categories.py)

---

### Module 4: Spending Over Time
[`modules/spending_over_time.py`](modules/spending_over_time.py) — **Unlocks:** Spending chart

*"How has my spending changed this week?"* — Use **Redis TimeSeries** to store and query spending by time range.

> Got stuck? [`solutions/spending_over_time.py`](solutions/spending_over_time.py)

---

## Workflow

1. Edit a module in `modules/`
2. **Apply your changes:**
   ```bash
   docker compose restart processor
   ```
3. Check the UI for your unlocked tab
