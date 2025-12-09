"""
TimeSeries Router

Endpoints for spending over time data (TimeSeries module).
"""

from fastapi import APIRouter, Depends, HTTPException
from api.dependencies import get_redis_client
from processor.modules import spending_over_time

router = APIRouter(prefix="/api/spending", tags=["timeseries"])


def get_latest_timestamp(redis) -> int:
    """Get timestamp of most recent data point from TimeSeries."""
    try:
        # Get the last data point from timeseries
        result = redis.ts().get("spending:timeseries")
        if result:
            return int(result[0])  # (timestamp, value) tuple
        return 0
    except:
        return 0


@router.get("/range")
def get_spending_range(
    start: int = None,
    end: int = None,
    days: int = None,
    redis=Depends(get_redis_client)
):
    """
    Get spending data for time range.

    Uses spending_over_time module (TimeSeries).

    Query params:
    - start: Start timestamp (milliseconds)
    - end: End timestamp (milliseconds)
    - days: Shortcut for last N days (overrides start/end)
    """
    try:
        # Calculate time range
        if days:
            # Use latest transaction timestamp as "now"
            end_ts = get_latest_timestamp(redis)
            if end_ts == 0:
                return {"data": [], "count": 0, "total_spent": 0}
            start_ts = end_ts - (days * 24 * 60 * 60 * 1000)
        elif start and end:
            start_ts = start
            end_ts = end
        else:
            raise HTTPException(
                status_code=400,
                detail="Provide either 'days' or both 'start' and 'end'"
            )

        # Query TimeSeries
        data_points = spending_over_time.get_spending_in_range(redis, start_ts, end_ts)

        # Format response
        result = [
            {"timestamp": int(ts), "amount": float(amount)}
            for ts, amount in data_points
        ]

        total = spending_over_time.get_total_spending_in_range(redis, start_ts, end_ts)

        return {
            "data": result,
            "count": len(result),
            "total_spent": total,
            "start": start_ts,
            "end": end_ts,
        }

    except HTTPException:
        raise
    except Exception as e:
        return {
            "data": [],
            "count": 0,
            "total_spent": 0,
            "error": str(e)
        }
