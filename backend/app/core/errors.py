from typing import Any

from fastapi import HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class ApiError(Exception):
	def __init__(
		self,
		code: str,
		message: str,
		*,
		status_code: int = 400,
		details: dict[str, Any] | list[Any] | None = None,
	) -> None:
		self.code = code
		self.message = message
		self.status_code = status_code
		self.details = details
		super().__init__(message)

	def to_dict(self) -> dict[str, Any]:
		payload: dict[str, Any] = {
			"code": self.code,
			"message": self.message,
		}
		if self.details is not None:
			payload["details"] = self.details
		return payload


def _http_exception_code(status_code: int) -> str:
	mapping = {
		400: "bad_request",
		401: "unauthorized",
		403: "forbidden",
		404: "not_found",
		409: "conflict",
		422: "validation_error",
		429: "rate_limited",
		500: "internal_error",
		502: "upstream_error",
		503: "service_unavailable",
	}
	return mapping.get(status_code, f"http_{status_code}")


def _detail_to_message(detail: Any) -> tuple[str, dict[str, Any] | list[Any] | None]:
	if isinstance(detail, str):
		return detail, None
	if isinstance(detail, dict):
		message = str(detail.get("message") or detail.get("detail") or "Ошибка API")
		return message, detail
	if isinstance(detail, list):
		return "Ошибка валидации запроса", detail
	return str(detail), None


async def api_error_handler(_: Request, error: ApiError) -> JSONResponse:
	return JSONResponse(status_code=error.status_code, content=error.to_dict())


async def http_exception_handler(_: Request, error: HTTPException) -> JSONResponse:
	message, details = _detail_to_message(error.detail)
	payload: dict[str, Any] = {
		"code": _http_exception_code(error.status_code),
		"message": message,
	}
	if details is not None:
		payload["details"] = details
	return JSONResponse(status_code=error.status_code, content=payload)


async def starlette_http_exception_handler(
	_: Request,
	error: StarletteHTTPException,
) -> JSONResponse:
	message, details = _detail_to_message(error.detail)
	payload: dict[str, Any] = {
		"code": _http_exception_code(error.status_code),
		"message": message,
	}
	if details is not None:
		payload["details"] = details
	return JSONResponse(status_code=error.status_code, content=payload)


async def validation_exception_handler(
	_: Request,
	error: RequestValidationError,
) -> JSONResponse:
	return JSONResponse(
		status_code=422,
		content={
			"code": "validation_error",
			"message": "Ошибка валидации запроса",
			"details": error.errors(),
		},
	)


async def unhandled_exception_handler(_: Request, error: Exception) -> JSONResponse:
	return JSONResponse(
		status_code=500,
		content={
			"code": "internal_error",
			"message": "Внутренняя ошибка сервера",
			"details": {"error": str(error)},
		},
	)
