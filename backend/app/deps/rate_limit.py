import json
import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import Request

from app.core.errors import ApiError
from app.services.cache_service import _get_redis


class InMemoryRateLimiter:
	def __init__(self) -> None:
		self._hits: dict[str, deque[float]] = defaultdict(deque)
		self._lock = Lock()

	def hit(self, key: str, *, limit: int, window_seconds: int) -> tuple[bool, int]:
		now = time.monotonic()
		window_start = now - window_seconds

		with self._lock:
			bucket = self._hits[key]
			while bucket and bucket[0] < window_start:
				bucket.popleft()

			if len(bucket) >= limit:
				retry_after = max(1, int(window_seconds - (now - bucket[0])))
				return False, retry_after

			bucket.append(now)
			return True, 0


rate_limiter = InMemoryRateLimiter()


def _client_key(request: Request, scope: str) -> str:
	client_host = request.client.host if request.client else "unknown"
	return f"{scope}:{client_host}"


def _redis_hit(key: str, *, limit: int, window_seconds: int) -> tuple[bool, int]:
	client = _get_redis()
	if client is None:
		return rate_limiter.hit(key, limit=limit, window_seconds=window_seconds)

	redis_key = f"rate:{key}"
	try:
		current = client.incr(redis_key)
		if current == 1:
			client.expire(redis_key, window_seconds)
		if current > limit:
			ttl = client.ttl(redis_key)
			return False, max(1, int(ttl))
		return True, 0
	except Exception:
		return rate_limiter.hit(key, limit=limit, window_seconds=window_seconds)


async def rate_limit_auth(request: Request) -> None:
	allowed, retry_after = _redis_hit(
		_client_key(request, "auth"),
		limit=20,
		window_seconds=60,
	)
	if not allowed:
		raise ApiError(
			"rate_limited",
			"Слишком много запросов. Попробуйте позже.",
			status_code=429,
			details={"retry_after_seconds": retry_after, "scope": "auth"},
		)


async def rate_limit_client_check(request: Request) -> None:
	allowed, retry_after = _redis_hit(
		_client_key(request, "client_check"),
		limit=30,
		window_seconds=60,
	)
	if not allowed:
		raise ApiError(
			"rate_limited",
			"Слишком много проверок клиента. Попробуйте позже.",
			status_code=429,
			details={"retry_after_seconds": retry_after, "scope": "client_check"},
		)
