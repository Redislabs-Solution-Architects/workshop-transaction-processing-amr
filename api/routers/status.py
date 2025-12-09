"""
Status Router

Checks which tabs should be unlocked based on Redis data.
"""

from fastapi import APIRouter, Depends
from api.dependencies import get_redis_client

router = APIRouter(prefix="/api", tags=["status"])


@router.get("/status")
def get_status(redis=Depends(get_redis_client)):
    """
    Check which features are unlocked.

    Returns unlock status for each tab based on Redis data presence.
    """
    # Check Transactions tab (needs List + JSON)
    transactions_unlocked = False
    try:
        list_exists = redis.exists("transactions:ordered")
        json_keys = redis.keys("transaction:*")
        transactions_unlocked = list_exists and len(json_keys) > 0
    except:
        pass

    # Check Spending Categories tab (needs Sorted Sets)
    categories_unlocked = False
    try:
        categories_exist = redis.exists("spending:categories")
        category_keys = redis.keys("spending:category:*")
        categories_unlocked = categories_exist and len(category_keys) > 0
    except:
        pass

    # Check Track Spending tab (needs TimeSeries)
    timeseries_unlocked = False
    try:
        ts_exists = redis.exists("spending:timeseries")
        timeseries_unlocked = ts_exists
    except:
        pass

    # Check Search tab (needs Vector index)
    search_unlocked = False
    try:
        # Check if vector index exists by trying to get info
        redis.ft("idx:transactions:vector").info()
        search_unlocked = True
    except:
        pass

    return {
        "transactions_unlocked": transactions_unlocked,
        "categories_unlocked": categories_unlocked,
        "timeseries_unlocked": timeseries_unlocked,
        "search_unlocked": search_unlocked,
    }
