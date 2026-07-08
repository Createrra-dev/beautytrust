import json
import logging
from typing import Any

import jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models

logger = logging.getLogger(__name__)

_AUDIT_METHODS = {"POST", "PUT", "PATCH", "DELETE"}


def extract_master_id_from_request(authorization: str | None) -> int | None:
	if not authorization or not authorization.startswith("Bearer "):
		return None

	token = authorization.removeprefix("Bearer ").strip()
	try:
		payload = jwt.decode(
			token,
			settings.auth_jwt_secret,
			algorithms=["HS256"],
			options={"verify_exp": False},
		)
		subject = payload.get("sub")
		if subject is None:
			return None
		return int(subject)
	except Exception:
		return None


def should_audit(method: str, path: str) -> bool:
	if method not in _AUDIT_METHODS:
		return False
	if not path.startswith("/api/"):
		return False
	if path in {"/api/health", "/api/payments/health"}:
		return False
	if path.startswith("/api/auth/otp/"):
		return False
	return True


def write_audit_log(
	db: Session,
	*,
	method: str,
	path: str,
	status_code: int,
	master_id: int | None = None,
	entity_type: str | None = None,
	entity_id: str | None = None,
	details: dict[str, Any] | None = None,
	ip_address: str | None = None,
	request_id: str | None = None,
) -> None:
	try:
		db.add(
			models.AuditLog(
				master_id=master_id,
				method=method,
				path=path,
				status_code=status_code,
				entity_type=entity_type,
				entity_id=entity_id,
				details_json=json.dumps(details, ensure_ascii=False) if details else None,
				ip_address=ip_address,
				request_id=request_id,
			)
		)
		db.commit()
	except Exception:
		logger.exception("audit_log_write_failed path=%s", path)
		db.rollback()
