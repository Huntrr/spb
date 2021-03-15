"""
Wrapper for Redis client.
"""
import functools
import os

import redis

@functools.lru_cache()
def redis_client() -> redis.Redis:
    """Returns a Redis client."""
    return redis.Redis(
        host=os.environ['REDIS_HOST'],
        port=os.environ['REDIS_PORT'],
        db=os.environ['REDIS_DB'],
        decode_responses=True)
