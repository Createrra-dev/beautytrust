import json
from typing import Any

from app.db import models

_DEFAULT_SETTINGS: dict[str, bool] = {
	"push_notifications_enabled": True,
	"email_notifications_enabled": True,
	"marketing_notifications_enabled": False,
}


def load_master_settings(master: models.Master) -> dict[str, bool]:
	raw = master.settings_json or "{}"
	try:
		parsed = json.loads(raw)
	except json.JSONDecodeError:
		parsed = {}

	settings = dict(_DEFAULT_SETTINGS)
	for key in _DEFAULT_SETTINGS:
		if key in parsed:
			settings[key] = bool(parsed[key])
	return settings


def merge_master_settings(
	master: models.Master,
	updates: dict[str, Any],
) -> dict[str, bool]:
	current = load_master_settings(master)
	for key, value in updates.items():
		if key in _DEFAULT_SETTINGS and value is not None:
			current[key] = bool(value)

	master.settings_json = json.dumps(current, ensure_ascii=False)
	return current
