from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.db.session import SessionLocal, get_db
from app.schemas.auth import (
	AuthTokenResponse,
	OtpCallStatusResponse,
	OtpSendRequest,
	OtpSendResponse,
	OtpVerifyRequest,
	PhoneCheckRequest,
	PhoneCheckResponse,
)
from app.deps.rate_limit import rate_limit_auth
from app.services.auth_service import (
	build_otp_send_response,
	create_access_token,
	create_otp_session,
	deliver_otp_session,
	normalize_phone_digits,
	phone_is_registered,
	prepare_registration_data,
	verify_otp_code,
	verify_otp_code_by_phone,
)
from app.services.zvonok_service import (
	OTP_CHANNEL_FLASH_CALL,
	ZVONOK_STATUS_IN_PROCESS,
	ZvonokError,
	get_flash_call_status,
)
from app.services.telegram_webhook import handle_telegram_update

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _flash_call_status_display(status: str | None, dial_status_display: str | None) -> str:
	if status == ZVONOK_STATUS_IN_PROCESS:
		return "Звоним на ваш номер..."
	if status == "compl_finished":
		return "Введите последние 4 цифры номера звонящего"
	if dial_status_display:
		return dial_status_display
	return "Ожидаем звонок..."


@router.post("/phone/check", response_model=PhoneCheckResponse, dependencies=[Depends(rate_limit_auth)])
async def check_phone(payload: PhoneCheckRequest, db: Session = Depends(get_db)) -> PhoneCheckResponse:
	try:
		phone_digits = normalize_phone_digits(payload.phone)
	except ValueError as error:
		raise HTTPException(status_code=400, detail=str(error)) from error

	return PhoneCheckResponse(registered=phone_is_registered(db, phone_digits))


@router.post("/otp/send", response_model=OtpSendResponse, dependencies=[Depends(rate_limit_auth)])
async def send_otp(payload: OtpSendRequest, db: Session = Depends(get_db)) -> OtpSendResponse:
	try:
		phone_digits = normalize_phone_digits(payload.phone)
	except ValueError as error:
		raise HTTPException(status_code=400, detail=str(error)) from error

	if payload.channel == OTP_CHANNEL_FLASH_CALL and not settings.zvonok_configured:
		raise HTTPException(
			status_code=503,
			detail="Подтверждение звонком временно недоступно. Используйте Telegram.",
		)

	is_registered = phone_is_registered(db, phone_digits)
	if payload.is_registration:
		if is_registered:
			raise HTTPException(
				status_code=400,
				detail="Вы уже зарегистрированы. Войдите в аккаунт.",
			)
	elif not is_registered:
		raise HTTPException(
			status_code=400,
			detail="Вы не зарегистрированы. Пройдите регистрацию.",
		)

	registration_first_name = None
	registration_email = None
	registration_password_hash = None
	if payload.is_registration:
		try:
			registration_first_name, registration_email, registration_password_hash = prepare_registration_data(
				db,
				payload.first_name,
				payload.email,
				payload.password,
			)
		except ValueError as error:
			raise HTTPException(status_code=400, detail=str(error)) from error

	try:
		session, otp_code = create_otp_session(
			db,
			phone_digits,
			delivery_channel=payload.channel,
			registration_first_name=registration_first_name,
			registration_email=registration_email,
			registration_password_hash=registration_password_hash,
		)
		code_sent = await deliver_otp_session(db, session, otp_code)
	except ZvonokError as error:
		raise HTTPException(status_code=503, detail=str(error)) from error

	response = build_otp_send_response(session, code_sent)
	return OtpSendResponse(**response)


@router.get("/otp/call-status", response_model=OtpCallStatusResponse, dependencies=[Depends(rate_limit_auth)])
async def get_otp_call_status(
	session_id: str,
	db: Session = Depends(get_db),
) -> OtpCallStatusResponse:
	session = db.scalar(
		select(models.OtpSession).where(models.OtpSession.session_token == session_id)
	)
	if session is None:
		raise HTTPException(status_code=404, detail="Сессия не найдена")

	if session.delivery_channel != OTP_CHANNEL_FLASH_CALL:
		return OtpCallStatusResponse(
			session_id=session.session_token,
			channel=session.delivery_channel,
			call_id=session.zvonok_call_id,
		)

	try:
		call_status = await get_flash_call_status(
			session.phone_digits,
			call_id=session.zvonok_call_id,
		)
	except ZvonokError as error:
		raise HTTPException(status_code=503, detail=str(error)) from error

	if call_status is None:
		return OtpCallStatusResponse(
			session_id=session.session_token,
			channel=session.delivery_channel,
			call_id=session.zvonok_call_id,
			call_status=ZVONOK_STATUS_IN_PROCESS,
			call_status_display="Ожидаем звонок...",
			completed=False,
		)

	status_display = _flash_call_status_display(
		call_status.status,
		call_status.dial_status_display or call_status.status_display,
	)

	return OtpCallStatusResponse(
		session_id=session.session_token,
		channel=session.delivery_channel,
		call_id=call_status.call_id,
		call_status=call_status.status,
		call_status_display=status_display,
		dial_status_display=call_status.dial_status_display,
		completed=False,
	)


@router.post("/otp/verify", response_model=AuthTokenResponse, dependencies=[Depends(rate_limit_auth)])
async def verify_otp(payload: OtpVerifyRequest, db: Session = Depends(get_db)) -> AuthTokenResponse:
	session = db.scalar(
		select(models.OtpSession).where(models.OtpSession.session_token == payload.session_id)
	)
	if session is None:
		raise HTTPException(status_code=400, detail="Сессия не найдена. Запросите код повторно.")

	existing_master = db.scalar(
		select(models.Master).where(models.Master.phone_digits == session.phone_digits)
	)
	is_new_user = existing_master is None

	try:
		master = verify_otp_code(
			db,
			payload.session_id,
			payload.code,
			first_name=payload.first_name,
			email=payload.email,
			password=payload.password,
		)
	except ValueError as error:
		if payload.phone:
			try:
				phone_digits = normalize_phone_digits(payload.phone)
				master = verify_otp_code_by_phone(
					db,
					phone_digits,
					payload.code,
					first_name=payload.first_name,
					email=payload.email,
					password=payload.password,
				)
			except ValueError as phone_error:
				raise HTTPException(status_code=400, detail=str(phone_error)) from phone_error
		else:
			raise HTTPException(status_code=400, detail=str(error)) from error

	token = create_access_token(master.id)
	return AuthTokenResponse(
		access_token=token,
		master_id=master.id,
		is_new_user=is_new_user,
	)


async def _process_telegram_update(update: dict) -> None:
	with SessionLocal() as db:
		await handle_telegram_update(db, update)


@router.post("/telegram/webhook")
async def telegram_webhook(
	request: Request,
	background_tasks: BackgroundTasks,
	secret_token: str | None = Header(default=None, alias="X-Telegram-Bot-Api-Secret-Token"),
) -> dict[str, bool]:
	if settings.telegram_webhook_secret and secret_token != settings.telegram_webhook_secret:
		raise HTTPException(status_code=403, detail="Invalid webhook secret")

	update = await request.json()
	background_tasks.add_task(_process_telegram_update, update)
	return {"ok": True}
