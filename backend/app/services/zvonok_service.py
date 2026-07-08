import logging
from dataclasses import dataclass

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

OTP_CHANNEL_TELEGRAM = "telegram"
OTP_CHANNEL_FLASH_CALL = "flash_call"

ZVONOK_STATUS_COMPLETED = "compl_finished"
ZVONOK_STATUS_IN_PROCESS = "in_process"


class ZvonokError(Exception):
	pass


@dataclass(frozen=True)
class FlashCallResult:
	pincode: str
	call_id: int


@dataclass(frozen=True)
class FlashCallStatus:
	call_id: int
	status: str
	status_display: str
	dial_status_display: str
	completed: bool
	phone: str


def format_phone_for_zvonok(phone_digits: str) -> str:
	return f"+7{phone_digits}"


def _api_params(phone_digits: str | None = None) -> dict[str, str]:
	params = {
		"public_key": settings.zvonok_public_key,
		"campaign_id": settings.zvonok_campaign_id,
	}
	if phone_digits is not None:
		params["phone"] = format_phone_for_zvonok(phone_digits)
	return params


def _normalize_pincode(raw_pincode: object) -> str:
	pincode = "".join(character for character in str(raw_pincode) if character.isdigit())
	if len(pincode) < 4:
		raise ZvonokError("Zvonok вернул некорректный код подтверждения")
	return pincode[-4:]


def _parse_call_record(record: dict) -> FlashCallStatus:
	call_id = int(record["call_id"])
	status = str(record.get("status") or record.get("call_status") or "")
	status_display = str(record.get("status_display") or record.get("call_status_display") or "")
	dial_status_display = str(record.get("dial_status_display") or "")
	return FlashCallStatus(
		call_id=call_id,
		status=status,
		status_display=status_display,
		dial_status_display=dial_status_display,
		completed=status == ZVONOK_STATUS_COMPLETED,
		phone=str(record.get("phone") or ""),
	)


async def _request_zvonok(path: str, phone_digits: str | None = None) -> object:
	if not settings.zvonok_configured:
		raise ZvonokError("Подтверждение звонком временно недоступно")

	api_url = f"{settings.zvonok_api_base_url.rstrip('/')}{path}"
	try:
		async with httpx.AsyncClient(timeout=30.0) as client:
			response = await client.get(api_url, params=_api_params(phone_digits))
			return response.json()
	except httpx.HTTPError as error:
		logger.exception("Zvonok API request failed: %s", path)
		raise ZvonokError("Не удалось связаться с Zvonok. Попробуйте позже.") from error


async def initiate_flash_call(phone_digits: str) -> FlashCallResult:
	payload = await _request_zvonok(
		"/manager/cabapi_external/api/v1/phones/flashcall/",
		phone_digits,
	)

	if isinstance(payload, dict) and payload.get("status") == "error":
		error_data = payload.get("data", "Не удалось инициировать звонок")
		logger.error("Zvonok flash call error: %s", error_data)
		raise ZvonokError(str(error_data))

	data = payload.get("data") if isinstance(payload, dict) else None
	if not isinstance(data, dict) or data.get("pincode") is None or data.get("call_id") is None:
		logger.error("Zvonok flash call unexpected response: %s", payload)
		raise ZvonokError("Не удалось получить код подтверждения от Zvonok")

	result = FlashCallResult(
		pincode=_normalize_pincode(data["pincode"]),
		call_id=int(data["call_id"]),
	)
	logger.info(
		"Zvonok flash call initiated for phone=%s call_id=%s",
		phone_digits,
		result.call_id,
	)
	return result


async def get_calls_by_phone(phone_digits: str) -> list[FlashCallStatus]:
	payload = await _request_zvonok(
		"/manager/cabapi_external/api/v1/phones/calls_by_phone/",
		phone_digits,
	)

	if isinstance(payload, dict) and payload.get("status") == "error":
		error_data = payload.get("data", "Не удалось получить статус звонка")
		logger.error("Zvonok calls_by_phone error: %s", error_data)
		raise ZvonokError(str(error_data))

	if not isinstance(payload, list):
		logger.error("Zvonok calls_by_phone unexpected response: %s", payload)
		raise ZvonokError("Не удалось получить статус звонка")

	return [_parse_call_record(record) for record in payload if isinstance(record, dict)]


async def get_flash_call_status(
	phone_digits: str,
	call_id: int | None = None,
) -> FlashCallStatus | None:
	calls = await get_calls_by_phone(phone_digits)
	if not calls:
		return None

	if call_id is not None:
		for call in calls:
			if call.call_id == call_id:
				return call
		return None

	return calls[0]
