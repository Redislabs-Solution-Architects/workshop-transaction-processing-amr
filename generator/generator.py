#!/usr/bin/env python3
"""
Transaction Service

Continuously generates realistic banking transactions and publishes them
to Redis Streams. Simulates a core banking system publishing transaction
events that will be processed by a consumer service.

Usage:
    # Default rate (1 transaction every 5 seconds)
    python generator.py
"""

import sys
import time
import os
from pathlib import Path
from typing import Optional
import signal
sys.path.insert(0, str(Path(__file__).parent.parent))
from lib.redis_client import get_redis, close_redis
from lib.logger import setup_logger
from transaction_models import generate_random_transaction
from dotenv import load_dotenv
load_dotenv()
logger = setup_logger(__name__)
shutdown_requested = False

def print_startup_banner(stream_key: str, delay: float, num_customers: int) -> None:
    """
    Print an informative startup banner.
    """
    logger.info("=" * 70)
    logger.info("Transaction Generator Starting")
    logger.info("=" * 70)
    logger.info(f"Transaction Rate: 1 transaction every {delay:.1f} seconds")
    logger.info(f"Stream Key: {stream_key}")

    # Show merchant statistics
    logger.info("-" * 70)
    logger.info("Starting transaction stream... (Press Ctrl+C to stop)")
    logger.info("-" * 70)

def format_transaction_log(tx, count: int) -> str:
    """
    Format transaction for logging with color coding based on amount.
    """
    merchant_str = f"{tx.merchant[:25]:25s}"
    amount_str = f"${tx.amount:8.2f}"
    return (
        f"[{count:6d}] {tx.transactionId} | "
        f"{merchant_str} | {amount_str} | "
        f"{tx.customerId} | {tx.category:12s}"
    )


def publish_transaction(redis, stream_key: str, tx) -> Optional[str]:
    """
    Publish a transaction to Redis Stream.
    """
    try:
        msg_id = redis.xadd(stream_key, tx.to_dict())
        return msg_id
    except Exception as e:
        logger.error(f" Failed to publish transaction: {e}")
        return None


def main() -> int:
    """
    Main transaction generator loop.

    Continuously generates and publishes realistic banking transactions
    to Redis Stream for processing.
    """
    global shutdown_requested

    try:
        # Get Redis connection
        redis = get_redis()

        # Configuration from environment
        stream_key = os.getenv("TRANSACTION_STREAM_KEY", "stream:transactions")
        delay = float(5)
        num_customers = 100

        print_startup_banner(stream_key, delay, num_customers)

        # Transaction counters
        count = 0
        error_count = 0

        base_timestamp = int(time.time() * 1000)  # Starting now in milliseconds
        hours_between_transactions = 5

        # Main generation loop
        while not shutdown_requested:
            try:
                # Generate transaction
                tx = generate_random_transaction(num_customers=num_customers)
                # Override timestamp to create time progression (5 hours after previous)
                tx.timestamp = base_timestamp + (count * hours_between_transactions * 60 * 60 * 1000)

                # Publish to Redis Stream
                msg_id = publish_transaction(redis, stream_key, tx)

                if msg_id:
                    count += 1
                    log_msg = format_transaction_log(tx, count)
                    logger.info(f"💳 {log_msg}")

                else:
                    error_count += 1
                    logger.error(f" Failed to publish transaction {count + 1}")

                # Sleep between transactions
                time.sleep(delay)

            except Exception as e:
                logger.error(f" Error generating transaction: {e}")
                error_count += 1
                time.sleep(delay)

      
        # Close Redis connection
        close_redis()
        return 0

    except KeyboardInterrupt:
        logger.info("\n Interrupted by user")
        return 0

    except Exception as e:
        logger.error(f" Fatal error: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
