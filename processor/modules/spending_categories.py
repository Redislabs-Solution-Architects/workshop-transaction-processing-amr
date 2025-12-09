"""
Module 3: Spending Categories

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

    # TODO 1: Increment category total spending. This adds to the existing score (or creates if new)
    # Key: "spending:categories"
    # Use ZINCRBY command
    pass

    # TODO 2: Increment merchant spending within category (aggregates if merchant exists)
    # Key: f"spending:category:{category}"
    # Use ZINCRBY command
    pass


def get_top_categories(redis_client, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top spending categories.
    Returns list of (category, total_amount) tuples.
    """
    # TODO: Get top categories from "spending:categories"
    # Use ZREVRANGE command and include scores
    return []


def get_top_merchants_in_category(redis_client, category: str, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top merchants within a specific category.
    Returns list of (merchant, total_amount) tuples.
    """
    # TODO: Get top merchants within a specific category from "spending:category:{category}"
    # Use ZREVRANGE command and include scores
    return []
