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

    # TODO: Replace the line below with:
    # Increment category total spending. This adds to the existing score (or creates if new). Add category name with amount.
    # Key: "spending:categories"
    pass

    # TODO: Replace the line below with:
    # Increment merchant spending within category (aggregates if merchant exists). Add merchant name with amount.
    # Key: f"spending:category:{category}"
    pass


def get_top_categories(redis_client, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top spending categories.
    Returns list of (category, total_amount) tuples.
    """

    # TODO: Replace the line below with:
    # Get all categories ordered by amount from "spending:categories".
    # Include scores (amount) in the result.
    return []


def get_top_merchants_in_category(redis_client, category: str, limit: int = 10) -> List[Tuple[str, float]]:
    """
    Get top merchants within a specific category.
    Returns list of (merchant, total_amount) tuples.
    """

    # TODO: Replace the line below with:
    # Get all merchants within a specific category ordered by amount from "spending:category:{category}"
    # Include scores (amount) in the result.
    return []
