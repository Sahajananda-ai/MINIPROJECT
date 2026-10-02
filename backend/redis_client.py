import redis
from .core.config import settings

def get_redis_client():
    """
    Returns a connected Redis client instance.
    Uses decode_responses=True so that strings are returned instead of bytes.
    """
    return redis.from_url(
        settings.REDIS_URL,
        decode_responses=True
    )

redis_client = get_redis_client()
