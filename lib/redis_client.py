"""
Redis client wrapper for the transaction workshop.

Provides a singleton Redis connection with connection pooling,
error handling, and configuration loading from environment variables.

Supports Azure Managed Redis with TLS.
"""

import os
from typing import Optional
import redis

# Global Redis client instance
_redis_client: Optional[redis.Redis] = None


def get_redis() -> redis.Redis:
    """
    Get or create a Redis client connection.

    Returns a singleton Redis client instance with connection pooling.
    Configuration is loaded from environment variables:
    - REDIS_HOST: Redis server hostname (default: localhost)
    - REDIS_PORT: Redis server port (default: 6379, Azure: 10000)
    - REDIS_PASSWORD: Redis password (default: None)
    - REDIS_SSL: Enable TLS/SSL connection (default: false, Azure: true)

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
        return _redis_client

    # Get configuration from environment
    host = os.getenv("REDIS_HOST", "localhost")
    port = int(os.getenv("REDIS_PORT", "6379"))
    password = os.getenv("REDIS_PASSWORD", None)
    use_ssl = os.getenv("REDIS_SSL", "false").lower() in ("true", "1", "yes")

    # Build Redis URL
    scheme = "rediss" if use_ssl else "redis"
    if password:
        redis_url = f"{scheme}://:{password}@{host}:{port}"
    else:
        redis_url = f"{scheme}://{host}:{port}"

    # Create Redis client using URL (handles SSL automatically)
    _redis_client = redis.from_url(
        redis_url,
        decode_responses=True,
        socket_keepalive=True,
        socket_connect_timeout=10,
        retry_on_timeout=True,
    )

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
