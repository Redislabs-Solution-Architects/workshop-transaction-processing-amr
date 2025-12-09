"""
Redis client wrapper for the transaction workshop.

Provides a singleton Redis connection with connection pooling,
error handling, and configuration loading from environment variables.
"""

import os
from typing import Optional
import redis
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Global Redis client instance
_redis_client: Optional[redis.Redis] = None


def get_redis() -> redis.Redis:
    """
    Get or create a Redis client connection.

    Returns a singleton Redis client instance with connection pooling.
    Configuration is loaded from environment variables:
    - REDIS_HOST: Redis server hostname (default: localhost)
    - REDIS_PORT: Redis server port (default: 6379)
    - REDIS_PASSWORD: Redis password (default: None)

    Returns:
        redis.Redis: Connected Redis client instance

    Raises:
        redis.ConnectionError: If unable to connect to Redis
        redis.RedisError: For other Redis-related errors

    Example:
        >>> r = get_redis()
        >>> r.ping()
        True
    """
    global _redis_client

    if _redis_client is not None:
        try:
            # Verify connection is still alive
            _redis_client.ping()
            return _redis_client
        except redis.ConnectionError:
            # Connection lost, will recreate below
            _redis_client = None

    # Get configuration from environment
    host = os.getenv("REDIS_HOST", "localhost")
    port = int(os.getenv("REDIS_PORT", "6379"))
    password = None

    # Create connection pool for better performance
    pool = redis.ConnectionPool(
        host=host,
        port=port,
        password=password if password else None,
        decode_responses=True,  # Auto-decode responses to strings
        max_connections=10,
        socket_keepalive=True,
        socket_connect_timeout=5,
        retry_on_timeout=True,
    )

    # Create Redis client
    _redis_client = redis.Redis(connection_pool=pool)

    # Test connection
    try:
        _redis_client.ping()
    except redis.ConnectionError as e:
        raise redis.ConnectionError(
            f"Failed to connect to Redis at {host}:{port}. "
            f"Make sure Redis is running. Error: {e}"
        ) from e

    return _redis_client


def close_redis() -> None:
    """
    Close the Redis connection and cleanup resources.

    This should be called when shutting down the application.
    """
    global _redis_client

    if _redis_client is not None:
        _redis_client.close()
        _redis_client = None


def reset_redis_client() -> None:
    """
    Reset the Redis client singleton.

    Useful for testing or when you need to force a reconnection.
    """
    global _redis_client

    if _redis_client is not None:
        _redis_client.close()

    _redis_client = None
