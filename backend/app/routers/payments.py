from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

from app.config import settings
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/api/payments", tags=["payments"])
payment_service = PaymentService()


class InitPaymentRequest(BaseModel):
	return_base_url: str | None = Field(
		default=None,
		description="URL бэкенда, доступный с устройства (для SuccessURL/FailURL)",
	)
	amount: int | None = Field(
		default=None,
		description="Сумма платежа в копейках",
	)
	description: str | None = Field(
		default=None,
		description="Описание платежа для T-Bank",
	)


class InitPaymentResponse(BaseModel):
	payment_id: str
	payment_url: str
	order_id: str
	amount: int


class PaymentStatusResponse(BaseModel):
	payment_id: str
	status: str
	success: bool
	order_id: str | None = None
	amount: int | None = None


def _resolve_return_base_url(requested_base_url: str | None) -> str:
	if requested_base_url:
		return requested_base_url.rstrip("/")
	return settings.public_base_url.rstrip("/")


def _to_status_response(record: dict) -> PaymentStatusResponse:
	return PaymentStatusResponse(
		payment_id=str(record["payment_id"]),
		status=str(record["status"]),
		success=bool(record["success"]),
		order_id=record.get("order_id"),
		amount=record.get("amount"),
	)


@router.get("/health")
async def health() -> dict[str, bool | str]:
	return {
		"status": "ok",
		"tbank_configured": settings.tbank_configured,
	}


@router.post("/init", response_model=InitPaymentResponse)
async def init_payment(body: InitPaymentRequest | None = None) -> InitPaymentResponse:
	if not settings.tbank_configured:
		raise HTTPException(
			status_code=500,
			detail="T-Bank credentials are not configured. Set TBANK_TERMINAL_KEY and TBANK_PASSWORD.",
		)

	return_base_url = _resolve_return_base_url(
		body.return_base_url if body else None,
	)
	order_id = f"order-{uuid4().hex[:16]}"
	amount = body.amount if body and body.amount else settings.payment_amount_kopecks
	description = (
		body.description
		if body and body.description
		else "Тестовая оплата 10 ₽"
	)

	attempt = payment_service.repository.create_attempt(
		order_id=order_id,
		amount=amount,
		description=description,
		status="INIT_PENDING",
	)

	try:
		result = await payment_service.init_payment(
			order_id=order_id,
			description=description,
			amount=amount,
			success_url=f"{return_base_url}/payments/return/success",
			fail_url=f"{return_base_url}/payments/return/fail",
		)
	except RuntimeError as error:
		payment_service.repository.mark_init_failed(
			attempt["id"],
			error_message=str(error),
		)
		raise HTTPException(status_code=502, detail=str(error)) from error
	except Exception as error:
		payment_service.repository.mark_init_failed(
			attempt["id"],
			error_message=f"T-Bank request failed: {error}",
		)
		raise HTTPException(status_code=502, detail=f"T-Bank request failed: {error}") from error

	payment_url = result.get("PaymentURL")
	payment_id = result.get("PaymentId")

	if not payment_url or not payment_id:
		payment_service.repository.mark_init_failed(
			attempt["id"],
			error_message="T-Bank Init response is missing PaymentURL or PaymentId",
		)
		raise HTTPException(status_code=502, detail="T-Bank Init response is missing PaymentURL or PaymentId")

	payment_service.repository.mark_init_success(
		attempt["id"],
		payment_id=str(payment_id),
		payment_url=str(payment_url),
		tbank_response=result,
	)

	return InitPaymentResponse(
		payment_id=str(payment_id),
		payment_url=str(payment_url),
		order_id=str(result.get("OrderId") or order_id),
		amount=amount,
	)


@router.get("/{payment_id}/status", response_model=PaymentStatusResponse)
async def payment_status(payment_id: str) -> PaymentStatusResponse:
	if not settings.tbank_configured:
		raise HTTPException(status_code=500, detail="T-Bank credentials are not configured.")

	try:
		record = await payment_service.refresh_payment_status(payment_id)
	except KeyError as error:
		raise HTTPException(status_code=404, detail=str(error)) from error
	except RuntimeError as error:
		raise HTTPException(status_code=502, detail=str(error)) from error
	except Exception as error:
		raise HTTPException(status_code=502, detail=f"T-Bank request failed: {error}") from error

	return _to_status_response(record)


return_router = APIRouter(prefix="/payments/return", tags=["payments-return"])


@return_router.get("/success", response_class=HTMLResponse)
async def payment_return_success(
	orderId: str | None = Query(default=None),
	paymentId: str | None = Query(default=None),
) -> HTMLResponse:
	payment_service.repository.mark_return_result(
		order_id=orderId,
		payment_id=paymentId,
		return_result="SUCCESS",
	)

	return HTMLResponse(
		"<html><body><h1>Оплата успешна</h1><p>Можно вернуться в приложение.</p></body></html>",
	)


@return_router.get("/fail", response_class=HTMLResponse)
async def payment_return_fail(
	orderId: str | None = Query(default=None),
	paymentId: str | None = Query(default=None),
) -> HTMLResponse:
	payment_service.repository.mark_return_result(
		order_id=orderId,
		payment_id=paymentId,
		return_result="FAIL",
	)

	return HTMLResponse(
		"<html><body><h1>Оплата не выполнена</h1><p>Можно вернуться в приложение.</p></body></html>",
	)
