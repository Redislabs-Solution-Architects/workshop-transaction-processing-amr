"""
Workshop Modules

Each module processes the same transaction and stores it in a different Redis data structure.
"""

from . import ordered_transactions
from . import store_transaction
from . import spending_categories
from . import spending_over_time

__all__ = [
    'ordered_transactions',
    'store_transaction',
    'spending_categories',
    'spending_over_time',
]
