import json
import logging
from typing import Any

from app.config import settings

logger = logging.getLogger(__name__)

_redis_client = None
_redis_checked = False


def _get_redis():
	global _redis_client, _redis_checked
	if _redis_checked:
		return _redis_client

	_redis_checked = True
	redis_url = settings.redis_url.strip()
	if not redis_url:
		return None

	try:
		import redis

		client = redis.from_url(redis_url, decode_responses=True, socket_connect_timeout=1)
		client.ping()
		_redis_client = client
		logger.info("Redis cache connected")
	except Exception as error:
		logger.warning("Redis unavailable, using in-memory fallback: %s", error)
		_redis_client = None

	return _redis_client


_memory_cache: dict[str, tuple[str, float]] = {}


def cache_get(key: str) -> str | None:
	client = _get_redis()
	if client is not None:
		try:
			return client.get(key)
		except Exception:
			logger.exception("redis_get_failed key=%s", key)

	import time

	item = _memory_cache.get(key)
	if item is None:
		return None
	value, expires_at = item
	if expires_at <= time.time():
		_memory_cache.pop(key, None)
		return None
	return value


def cache_set(key: str, value: str, ttl_seconds: int) -> None:
	client = _get_redis()
	if client is not None:
		try:
			client.setex(key, ttl_seconds, value)
			return
		except Exception:
			logger.exception("redis_set_failed key=%s", key)

	import time

	_memory_cache[key] = (value, time.time() + ttl_seconds)


def cache_delete_prefix(prefix: str) -> None:
	client = _get_redis()
	if client is not None:
		try:
			for key in client.scan_iter(match=f"{prefix}*"):
				client.delete(key)
			return
		except Exception:
			logger.exception("redis_delete_prefix_failed prefix=%s", prefix)

	for key in list(_memory_cache):
		if key.startswith(prefix):
			_memory_cache.pop(key, None)


def cache_get_json(key: str) -> Any | None:
	raw = cache_get(key)
	if raw is None:
		return None
	try:
		return json.loads(raw)
	except json.JSONDecodeError:
		return None


def cache_set_json(key: str, value: Any, ttl_seconds: int) -> None:
	cache_set(key, json.dumps(value, ensure_ascii=False), ttl_seconds)
