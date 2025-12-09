"""
Module 1: Ordered Transactions - SOLUTION

Store transactions in a Redis List, ordered from newest to oldest.
This provides a simple timeline of all transactions.
"""

from typing import List, Dict


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Add transaction ID to ordered list (newest first).
    """
    tx_id = tx_data.get('transactionId')
    redis_client.lpush("transactions:ordered", tx_id)


def get_recent_transactions(redis_client, limit: int = 10) -> List[str]:
    """
    Retrieve most recent transactions from list.
    Returns list of transaction IDs, newest first.
    """
    return redis_client.lrange("transactions:ordered", 0, limit - 1)
