#!/usr/bin/env python3
"""
Transaction Consumer

Consumes transactions from Redis Stream and dispatches to all modules.
This is pre-built - workshop developers don't modify this file.
"""

import sys
import time
from pathlib import Path
from typing import Dict

sys.path.insert(0, str(Path(__file__).parent.parent))

from lib.redis_client import get_redis
from lib.logger import setup_logger

# Import all module processors
from modules import ordered_transactions
from modules import store_transaction
from modules import spending_categories
from modules import spending_over_time

logger = setup_logger("consumer")

def dispatch_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """
    Dispatch transaction to all module processors.

    Each module receives the same transaction and stores it
    in a different Redis data structure.
    """
    # Module 1: Add to ordered list
    ordered_transactions.process_transaction(redis_client, tx_data)

    # Module 2: Store as JSON document
    store_transaction.process_transaction(redis_client, tx_data)

    # Module 3: Update spending category rankings
    spending_categories.process_transaction(redis_client, tx_data)

    # Module 4: Add to time-series
    spending_over_time.process_transaction(redis_client, tx_data)


def ensure_consumer_group(redis_client, stream_key: str, group_name: str) -> None:
    """Create consumer group if it doesn't exist."""
    try:
        redis_client.xgroup_create(stream_key, group_name, id='0', mkstream=True)
        logger.info(f"Consumer group '{group_name}' created")
    except Exception as e:
        if "BUSYGROUP" in str(e):
            logger.info(f"Consumer group '{group_name}' already exists")
        else:
            raise


def main() -> None:
    """Main consumer loop - consumes once, dispatches to all modules."""

    STREAM_KEY = "stream:transactions"
    GROUP_NAME = "consumer-group:processor"
    CONSUMER_NAME = "processor-1"
    BATCH_SIZE = 10
    BLOCK_MS = 1000

    redis = get_redis()
    ensure_consumer_group(redis, STREAM_KEY, GROUP_NAME)

    logger.info("=" * 70)
    logger.info("Transaction Processor Starting")
    logger.info("=" * 70)
    logger.info(f"Stream: {STREAM_KEY}")
    logger.info(f"Dispatching to 4 modules:")
    logger.info("  1. ordered_transactions  - List")
    logger.info("  2. store_transaction     - JSON")
    logger.info("  3. spending_categories   - Sorted Sets")
    logger.info("  4. spending_over_time    - TimeSeries")
    logger.info("=" * 70)

    processed_count = 0
    start_time = time.time()

    try:
        while True:
            # Consume from stream
            messages = redis.xreadgroup(
                groupname=GROUP_NAME,
                consumername=CONSUMER_NAME,
                streams={STREAM_KEY: '>'},
                count=BATCH_SIZE,
                block=BLOCK_MS
            )

            if not messages:
                continue

            for stream, message_list in messages:
                for message_id, data in message_list:
                    # Convert bytes to strings
                    tx_data = {
                        key.decode() if isinstance(key, bytes) else key:
                        value.decode() if isinstance(value, bytes) else value
                        for key, value in data.items()
                    }

                    # Dispatch to all modules
                    dispatch_transaction(redis, tx_data)

                    # Acknowledge message
                    redis.xack(stream, GROUP_NAME, message_id)

                    processed_count += 1

                    # Log progress
                    if processed_count % 50 == 0:
                        elapsed = time.time() - start_time
                        tps = processed_count / elapsed if elapsed > 0 else 0
                        logger.info(f"Processed: {processed_count} | TPS: {tps:.2f}")

    except KeyboardInterrupt:
        logger.info("\n" + "=" * 70)
        logger.info("Processor Stopped")
        logger.info(f"Total Processed: {processed_count:,}")
        logger.info("=" * 70)

    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    main()
