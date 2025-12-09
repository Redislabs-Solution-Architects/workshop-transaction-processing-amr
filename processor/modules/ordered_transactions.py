"""
Module 1: Ordered Transactions

Store transactions in a Redis List, ordered from newest to oldest.
This provides a simple timeline of all transactions.
"""

from typing import List, Dict


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Add transaction ID to ordered list (newest first).
    """
    tx_id = tx_data.get('transactionId')

    # TODO: Replace the line below with:
    # Add transaction ID to the beginning of the list "transactions:ordered".
    # This keeps newest transactions at the front (index 0).
    pass


def get_recent_transactions(redis_client, limit: int = 10) -> List[str]:
    """
    Retrieve most recent transactions from list.
    Returns list of transaction IDs, newest first.

    """
    # TODO: Replace the line below with:
    # Get transaction IDs from "transactions:ordered"
    # Get a range of items from the list.
    # Start at 0 (newest), end at limit-1.
    return []
