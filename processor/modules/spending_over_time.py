"""
Module 4: Spending Over Time - SOLUTION

Track spending over time using Redis TimeSeries.
Enables time-range queries like "spending in last 7 days".
"""

from typing import List, Tuple, Dict


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Add transaction to time-series.
    """
    amount = float(tx_data.get('amount', 0))
    timestamp = int(tx_data.get('timestamp', 0))

    redis_client.ts().add("spending:timeseries", timestamp, amount)


def get_spending_in_range(redis_client, start_time: int, end_time: int) -> List[Tuple[int, float]]:
    """
    Get spending data points in time range.
    Returns list of (timestamp, amount) tuples.
    """
    return redis_client.ts().range("spending:timeseries", start_time, end_time)


def get_total_spending_in_range(redis_client, start_time: int, end_time: int) -> float:
    """
    Get total spending in time range.
    """
    data_points = get_spending_in_range(redis_client, start_time, end_time)
    return sum(amount for _, amount in data_points)
