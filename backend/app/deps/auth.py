import jwt
from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.db.session import get_db


def get_current_master_id(authorization: str | None = Header(default=None)) -> int:
	if authorization is None or not authorization.startswith("Bearer "):
		raise HTTPException(status_code=401, detail="Требуется авторизация")

	token = authorization.removeprefix("Bearer ").strip()
	if not token:
		raise HTTPException(status_code=401, detail="Требуется авторизация")

	try:
		payload = jwt.decode(token, settings.auth_jwt_secret, algorithms=["HS256"])
		master_id = int(payload["sub"])
	except (jwt.PyJWTError, KeyError, TypeError, ValueError) as error:
		raise HTTPException(status_code=401, detail="Недействительный токен") from error

	return master_id


def get_current_master(
	master_id: int = Depends(get_current_master_id),
	db: Session = Depends(get_db),
) -> models.Master:
	master = db.get(models.Master, master_id)
	if master is None:
		raise HTTPException(status_code=404, detail="Профиль не найден")
	return master
