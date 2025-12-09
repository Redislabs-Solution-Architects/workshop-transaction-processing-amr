"""
Module 2: Store Transaction

Store complete transaction as a JSON document in Redis.
This provides the source of truth for all transaction data.
"""

from typing import Dict, List, Optional


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Store transaction as JSON document.
    """
    tx_id = tx_data.get('transactionId')

    transaction = {
        'transactionId': tx_id,
        'customerId': tx_data.get('customerId'),
        'amount': float(tx_data.get('amount', 0)),
        'merchant': tx_data.get('merchant'),
        'category': tx_data.get('category'),
        'timestamp': int(tx_data.get('timestamp', 0)),
        'location': tx_data.get('location'),
        'cardLast4': tx_data.get('cardLast4'),
    }

    # TODO: Replace the line below with:
    # Add JSON to Redis
    # Key format: f"transaction:{tx_id}"
    # Path: "$" (root)
    pass


def get_transaction(redis_client, tx_id: str) -> Optional[Dict]:
    """
    Retrieve a single transaction by ID.
    """
    # TODO: Replace the line below with:
    # Retrieve JSON from Redis
    # Key format: f"transaction:{tx_id}"
    # Path: "$" (root)
    result = None

    return result[0] if result else None

def get_transactions_by_ids(redis_client, tx_ids: List[str]) -> List[Dict]:
    """
    Retrieve multiple transactions by IDs using JSON.MGET.
    Single Redis call for all documents.
    """
    if not tx_ids:
        return []

    keys = [f"transaction:{tx_id}" for tx_id in tx_ids]
    
    # TODO: Replace the line below with:
    # Fetch JSON for the keys defined above, in one call
    # Path: "$" (root)
    results = []

    transactions = []
    for result in results:
        if result and result[0]:
            transactions.append(result[0])

    return transactions
