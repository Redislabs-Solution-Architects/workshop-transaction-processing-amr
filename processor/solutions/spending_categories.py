"""
Module 3: Spending Categories - SOLUTION

Track spending by category using Redis Sorted Sets.
Maintains:
1. Overall category spending (total amount per category)
2. Top merchants per category (aggregated spending)
"""

from typing import List, Dict, Tuple


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Update category spending sorted sets.
    """
    category = tx_data.get('category')
    merchant = tx_data.get('merchant')
    amount = float(tx_data.get('amount', 0))

    # Increment category total spending
    redis_client.zincrby("spending:categories", amount, category)

    # Increment merchant spending within category (aggregates if merchant exists)
    redis_client.zincrby(f"spending:category:{category}", amount, merchant)


def get_top_categories(redis_client, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top spending categories.
    Returns list of (category, total_amount) tuples.
    """
    return redis_client.zrevrange("spending:categories", 0, limit - 1, withscores=True)


def get_top_merchants_in_category(redis_client, category: str, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top merchants within a specific category.
    Returns list of (merchant, total_amount) tuples.
    """
    return redis_client.zrevrange(f"spending:category:{category}", 0, limit - 1, withscores=True)
