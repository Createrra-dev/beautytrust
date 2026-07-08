import logging

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.db.session import SessionLocal
from app.services.audit_service import (
	extract_master_id_from_request,
	should_audit,
	write_audit_log,
)

logger = logging.getLogger(__name__)


class AuditLogMiddleware(BaseHTTPMiddleware):
	async def dispatch(self, request: Request, call_next) -> Response:
		response = await call_next(request)
		method = request.method.upper()
		path = request.url.path

		if not should_audit(method, path):
			return response

		master_id = extract_master_id_from_request(request.headers.get("Authorization"))
		request_id = response.headers.get("X-Request-Id")
		client_host = request.client.host if request.client else None

		try:
			with SessionLocal() as db:
				write_audit_log(
					db,
					method=method,
					path=path,
					status_code=response.status_code,
					master_id=master_id,
					ip_address=client_host,
					request_id=request_id,
				)
		except Exception:
			logger.exception("audit_middleware_failed path=%s", path)

		return response
