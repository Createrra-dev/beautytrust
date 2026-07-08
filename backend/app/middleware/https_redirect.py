from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import RedirectResponse, Response

from app.config import settings


class HttpsRedirectMiddleware(BaseHTTPMiddleware):
	async def dispatch(self, request: Request, call_next) -> Response:
		if not settings.force_https:
			return await call_next(request)

		forwarded_proto = request.headers.get("X-Forwarded-Proto", "").lower()
		if forwarded_proto == "https" or request.url.scheme == "https":
			return await call_next(request)

		target = request.url.replace(scheme="https")
		return RedirectResponse(url=str(target), status_code=308)
