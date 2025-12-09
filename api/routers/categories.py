"""
Categories Router

Endpoints for spending category data (Sorted Sets module).
"""

from fastapi import APIRouter, Depends
from api.dependencies import get_redis_client
from processor.modules import spending_categories

router = APIRouter(prefix="/api/categories", tags=["categories"])


@router.get("/top")
def get_top_categories(limit: int = 10, redis=Depends(get_redis_client)):
    """
    Get top spending categories.

    Uses spending_categories module (Sorted Set).
    """
    try:
        categories = spending_categories.get_top_categories(redis, limit)
        # Convert to dict format
        result = [
            {"category": cat, "total_spent": float(amount)}
            for cat, amount in categories
        ]
        return {"categories": result, "count": len(result)}
    except Exception as e:
        return {"categories": [], "count": 0, "error": str(e)}


@router.get("/{category}/top")
def get_top_in_category(category: str, limit: int = 10, redis=Depends(get_redis_client)):
    """
    Get top merchants in a specific category.

    Uses spending_categories module (Sorted Set).
    """
    try:
        merchants = spending_categories.get_top_merchants_in_category(redis, category, limit)
        result = [
            {"merchant": merchant, "amount": float(amount)}
            for merchant, amount in merchants
        ]
        return {"merchants": result, "count": len(result), "category": category}
    except Exception as e:
        return {"merchants": [], "count": 0, "category": category, "error": str(e)}
