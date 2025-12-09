"""
API Dependencies

Provides Redis client and module access.
"""

from lib.redis_client import get_redis
from processor.modules import (
    ordered_transactions,
    store_transaction,
    spending_categories,
    spending_over_time,
    vector_search,
)


def get_redis_client():
    """Get Redis client instance."""
    return get_redis()
