"""
Stream Router

Direct stream access for real-time transaction display.
"""

from fastapi import APIRouter, Depends
from api.dependencies import get_redis_client

router = APIRouter(prefix="/api/stream", tags=["stream"])


@router.get("/latest")
def get_latest_transaction(after: str = "0", redis=Depends(get_redis_client)):
    """
    Get latest transaction from stream after given ID.
    Used by startup screen to show live transactions.
    """
    try:
        # Read from stream starting after the given ID
        messages = redis.xread(
            streams={"stream:transactions": after},
            count=1,
            block=100  # Block for 100ms
        )

        if messages:
            stream_name, message_list = messages[0]
            if message_list:
                stream_id, data = message_list[0]

                # Decode the transaction data
                transaction = {
                    key.decode() if isinstance(key, bytes) else key:
                    value.decode() if isinstance(value, bytes) else value
                    for key, value in data.items()
                }

                return {
                    "stream_id": stream_id.decode() if isinstance(stream_id, bytes) else stream_id,
                    "transaction": transaction
                }

        return {"stream_id": after, "transaction": None}

    except Exception as e:
        return {"stream_id": after, "transaction": None, "error": str(e)}
