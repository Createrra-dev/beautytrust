import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("beautytrust.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
	async def dispatch(self, request: Request, call_next) -> Response:
		request_id = request.headers.get("X-Request-Id") or str(uuid.uuid4())
		started_at = time.perf_counter()
		status_code = 500

		try:
			response = await call_next(request)
			status_code = response.status_code
			response.headers["X-Request-Id"] = request_id
			return response
		except Exception:
			logger.exception(
				"request_failed request_id=%s method=%s path=%s",
				request_id,
				request.method,
				request.url.path,
			)
			raise
		finally:
			elapsed_ms = int((time.perf_counter() - started_at) * 1000)
			logger.info(
				"request request_id=%s method=%s path=%s status=%s duration_ms=%s client=%s",
				request_id,
				request.method,
				request.url.path,
				status_code,
				elapsed_ms,
				request.client.host if request.client else "-",
			)
