"""
Transactions Router

Endpoints for transaction data (List + JSON modules).
"""

from fastapi import APIRouter, Depends, HTTPException
from api.dependencies import get_redis_client
from processor.modules import ordered_transactions, store_transaction

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


@router.get("/recent")
def get_recent_transactions(limit: int = 20, redis=Depends(get_redis_client)):
    """
    Get recent transactions with full details, ordered newest first.

    Optimized: 2 Redis calls total
    1. LRANGE to get IDs from List
    2. JSON.MGET to fetch all documents at once
    """
    try:
        tx_ids = ordered_transactions.get_recent_transactions(redis, limit)
        if not tx_ids:
            return {"transactions": [], "count": 0}

        transactions = store_transaction.get_transactions_by_ids(redis, tx_ids)
        return {"transactions": transactions, "count": len(transactions)}
    except Exception as e:
        return {"transactions": [], "count": 0, "error": str(e)}


@router.get("/{transaction_id}")
def get_transaction(transaction_id: str, redis=Depends(get_redis_client)):
    """
    Get single transaction by ID.
    """
    try:
        transaction = store_transaction.get_transaction(redis, transaction_id)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        return transaction
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
