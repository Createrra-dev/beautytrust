from pathlib import Path

from app.config import settings
from app.db import models


def uploads_root() -> Path:
	path = Path(settings.uploads_dir)
	if not path.is_absolute():
		path = Path(__file__).resolve().parents[2] / path
	return path


def avatar_url_for(master: models.Master) -> str | None:
	if not master.avatar_path:
		return None
	return upload_url_for_path(master.avatar_path)


def upload_url_for_path(relative_path: str) -> str:
	return f"{settings.public_base_url.rstrip('/')}/uploads/{relative_path}"


def yclients_staff_avatar_url_for(appointment: models.Appointment) -> str | None:
	if not appointment.yclients_staff_avatar_path:
		return None
	return upload_url_for_path(appointment.yclients_staff_avatar_path)
