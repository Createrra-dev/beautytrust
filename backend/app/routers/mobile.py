from calendar import monthrange
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy import and_, extract, func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.db import models
from app.db.session import get_db
from app.deps.auth import get_current_master
from app.deps.rate_limit import rate_limit_client_check
from app.schemas.api import (
	AppointmentCreateRequest,
	AppointmentSchema,
	AppointmentUpdateRequest,
	CheckHistoryRecordSchema,
	ClientCheckResponse,
	ClientProfileSchema,
	CommunityMessageCreateRequest,
	CommunityMessageSchema,
	CommunityTopicCreateRequest,
	CommunityTopicSchema,
	DashboardPeriodSchema,
	DashboardStatsSchema,
	MasterProfileSchema,
	MasterProfileUpdateRequest,
	MasterReviewSchema,
	MasterServiceCreateRequest,
	MasterServiceSchema,
	MasterServiceUpdateRequest,
	PhoneCheckRequest,
	SupportMessageCreateRequest,
	SupportTicketCreateRequest,
	SupportTicketSchema,
	VisitResultSchema,
)
from app.services.password_service import normalize_email
from app.services.uploads import avatar_url_for, uploads_root

_RU_MONTHS = (
	"",
	"Январь",
	"Февраль",
	"Март",
	"Апрель",
	"Май",
	"Июнь",
	"Июль",
	"Август",
	"Сентябрь",
	"Октябрь",
	"Ноябрь",
	"Декабрь",
)

_RU_MONTHS_PREPOSITIONAL = (
	"",
	"январю",
	"февралю",
	"марту",
	"апрелю",
	"маю",
	"июню",
	"июлю",
	"августу",
	"сентябрю",
	"октябрю",
	"ноябрю",
	"декабрю",
)

_DEFAULT_SPARKLINE = [0.4, 0.45, 0.5, 0.48, 0.58, 0.62, 0.7, 0.68, 0.8, 0.86, 0.92, 1.0]

router = APIRouter(prefix="/api", tags=["mobile"])


def _format_phone(digits: str) -> str:
	return f"+7 ({digits[0:3]}) {digits[3:6]}-{digits[6:8]}-{digits[8:10]}"


def _initials(name: str) -> str:
	parts = [part for part in name.strip().split() if part]
	if not parts:
		return "?"
	if len(parts) == 1:
		return parts[0][0].upper()
	return f"{parts[0][0]}{parts[1][0]}".upper()


def _profile_schema(profile: models.ClientProfile) -> ClientProfileSchema:
	return ClientProfileSchema(
		phone=_format_phone(profile.phone_digits),
		rating_label=profile.rating_label,
		reviews_average=profile.reviews_average,
		reviews_count=profile.reviews_count,
		no_shows_count=profile.no_shows_count,
		scandals_count=profile.scandals_count,
		reviews=[
			MasterReviewSchema(
				author_name=review.author_name,
				rating=review.rating,
				text=review.text,
				review_month=review.review_month,
				review_year=review.review_year,
			)
			for review in profile.reviews
		],
		reliability_title=profile.reliability_title,
		reliability_subtitle=profile.reliability_subtitle,
	)


def _appointment_schema(appointment: models.Appointment) -> AppointmentSchema:
	visit_result = None
	if appointment.visit_result:
		visit_result = VisitResultSchema(
			punctuality=appointment.visit_result.punctuality,
			paid_in_full=appointment.visit_result.paid_in_full,
			had_scandal=appointment.visit_result.had_scandal,
			left_tips=appointment.visit_result.left_tips,
			comment=appointment.visit_result.comment,
		)

	return AppointmentSchema(
		id=appointment.external_id,
		client_name=appointment.client_name,
		client_phone_digits=appointment.client_phone_digits,
		service_name=appointment.service_name,
		service_duration_label=appointment.service_duration_label,
		scheduled_at=appointment.scheduled_at,
		service_price=appointment.service_price,
		client_rating=appointment.client_rating,
		risk_level=appointment.risk_level,
		days_since_verified=appointment.days_since_verified,
		visit_result=visit_result,
	)


def _get_master_appointment(
	db: Session,
	master_id: int,
	appointment_id: str,
) -> models.Appointment:
	appointment = db.scalar(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(
			models.Appointment.external_id == appointment_id,
			models.Appointment.master_id == master_id,
		)
	)
	if appointment is None:
		raise HTTPException(status_code=404, detail="Appointment not found")
	return appointment


def _get_master_support_ticket(
	db: Session,
	master_id: int,
	ticket_id: str,
) -> models.SupportTicket:
	ticket = db.scalar(
		select(models.SupportTicket).where(
			models.SupportTicket.external_id == ticket_id,
			models.SupportTicket.master_id == master_id,
		)
	)
	if ticket is None:
		raise HTTPException(status_code=404, detail="Ticket not found")
	return ticket


def _period_label(year: int, month: int) -> str:
	return f"{_RU_MONTHS[month]} {year}"


def _month_bounds(year: int, month: int) -> tuple[datetime, datetime]:
	start = datetime(year, month, 1, tzinfo=timezone.utc)
	last_day = monthrange(year, month)[1]
	end = datetime(year, month, last_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
	return start, end


def _previous_month(year: int, month: int) -> tuple[int, int]:
	if month == 1:
		return year - 1, 12
	return year, month - 1


def _risk_level_from_rating(rating: float) -> str:
	if rating >= 4:
		return "low"
	if rating >= 3:
		return "medium"
	return "high"


def _percent_trend_label(current: int, previous: int, compare_month: int) -> str:
	month_gen = _RU_MONTHS_PREPOSITIONAL[compare_month]
	if previous == 0:
		if current == 0:
			return f"0 к {month_gen}"
		return f"+100% к {month_gen}"
	delta_pct = round(((current - previous) / previous) * 100)
	sign = "+" if delta_pct > 0 else ""
	return f"{sign}{delta_pct}% к {month_gen}"


def _count_trend_label(current: int, previous: int, compare_month: int) -> str:
	month_gen = _RU_MONTHS_PREPOSITIONAL[compare_month]
	delta = current - previous
	sign = "+" if delta > 0 else ""
	return f"{sign}{delta} к {month_gen}"


def _dashboard_metrics(db: Session, master_id: int, year: int, month: int) -> tuple[int, int, int]:
	start, end = _month_bounds(year, month)
	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(
			models.Appointment.master_id == master_id,
			models.Appointment.scheduled_at >= start,
			models.Appointment.scheduled_at <= end,
		)
	).unique().all()

	protected_income = 0
	prevented_no_shows = 0
	for appointment in appointments:
		visit = appointment.visit_result
		if visit is None or visit.punctuality == "noShow":
			continue
		protected_income += appointment.service_price
		if appointment.risk_level == "high":
			prevented_no_shows += 1

	completed_checks = db.scalar(
		select(func.count())
		.select_from(models.CheckHistoryRecord)
		.where(
			models.CheckHistoryRecord.master_id == master_id,
			models.CheckHistoryRecord.checked_at >= start,
			models.CheckHistoryRecord.checked_at <= end,
		)
	) or 0

	return protected_income, prevented_no_shows, int(completed_checks)


def _sparkline_values(db: Session, master_id: int, year: int, month: int) -> list[float]:
	start, end = _month_bounds(year, month)
	rows = db.execute(
		select(
			extract("day", models.Appointment.scheduled_at).label("day"),
			func.coalesce(func.sum(models.Appointment.service_price), 0).label("income"),
		)
		.join(models.VisitResult, models.VisitResult.appointment_id == models.Appointment.id)
		.where(
			models.Appointment.master_id == master_id,
			models.Appointment.scheduled_at >= start,
			models.Appointment.scheduled_at <= end,
			models.VisitResult.punctuality != "noShow",
		)
		.group_by("day")
	).all()

	if not rows:
		return list(_DEFAULT_SPARKLINE)

	days_in_month = monthrange(year, month)[1]
	daily = [0.0] * days_in_month
	for day, income in rows:
		daily[int(day) - 1] = float(income)

	# Compress into 12 buckets for the chart.
	bucket_count = 12
	buckets = [0.0] * bucket_count
	for index, value in enumerate(daily):
		bucket_index = min(bucket_count - 1, (index * bucket_count) // days_in_month)
		buckets[bucket_index] += value

	peak = max(buckets)
	if peak <= 0:
		return list(_DEFAULT_SPARKLINE)
	return [round(value / peak, 4) for value in buckets]


def _get_master_service(
	db: Session,
	master_id: int,
	service_id: int,
) -> models.MasterService:
	service = db.scalar(
		select(models.MasterService).where(
			models.MasterService.id == service_id,
			or_(
				models.MasterService.master_id == master_id,
				models.MasterService.master_id.is_(None),
			),
		)
	)
	if service is None:
		raise HTTPException(status_code=404, detail="Service not found")
	return service


@router.get("/health")
async def api_health() -> dict[str, str]:
	return {"status": "ok", "service": "beautytrust-api"}


def _years_experience(master: models.Master) -> int:
	created = master.created_at
	if created is None:
		return 0
	if created.tzinfo is None:
		created = created.replace(tzinfo=timezone.utc)
	days = max(0, (datetime.now(timezone.utc) - created).days)
	return days // 365


def _refresh_master_stats(db: Session, master: models.Master) -> None:
	clients_count = db.scalar(
		select(func.count(func.distinct(models.Appointment.client_phone_digits))).where(
			models.Appointment.master_id == master.id,
		)
	) or 0

	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(models.Appointment.master_id == master.id)
	).unique().all()

	protected_income = 0
	prevented_no_shows = 0
	for appointment in appointments:
		visit = appointment.visit_result
		if visit is None or visit.punctuality == "noShow":
			continue
		protected_income += appointment.service_price
		if appointment.risk_level == "high":
			prevented_no_shows += 1

	master.clients_count = int(clients_count)
	master.protected_income = protected_income
	master.prevented_no_shows = prevented_no_shows
	db.add(master)
	db.commit()
	db.refresh(master)


def _master_profile_schema(master: models.Master) -> MasterProfileSchema:
	return MasterProfileSchema(
		first_name=master.first_name,
		badge_label=master.badge_label,
		rating=master.rating,
		reviews_count=master.reviews_count,
		clients_count=master.clients_count,
		prevented_no_shows=master.prevented_no_shows,
		protected_income=master.protected_income,
		tariff_label=master.tariff_label,
		avatar_url=avatar_url_for(master),
		email=master.email,
		phone_digits=master.phone_digits,
		years_experience=_years_experience(master),
	)


def _delete_avatar_file(relative_path: str | None) -> None:
	if not relative_path:
		return
	file_path = uploads_root() / relative_path
	if file_path.is_file():
		file_path.unlink()


@router.get("/profile", response_model=MasterProfileSchema)
async def get_profile(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	_refresh_master_stats(db, master)
	return _master_profile_schema(master)


@router.patch("/profile", response_model=MasterProfileSchema)
async def update_profile(
	body: MasterProfileUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	if body.first_name is not None:
		first_name = body.first_name.strip()
		if len(first_name) < 2:
			raise HTTPException(status_code=400, detail="Имя слишком короткое")
		if len(first_name) > 120:
			raise HTTPException(status_code=400, detail="Имя слишком длинное")
		master.first_name = first_name

	if body.badge_label is not None:
		badge_label = body.badge_label.strip()
		if not badge_label:
			raise HTTPException(status_code=400, detail="Значок не может быть пустым")
		if len(badge_label) > 120:
			raise HTTPException(status_code=400, detail="Значок слишком длинный")
		master.badge_label = badge_label

	if body.email is not None:
		try:
			normalized = normalize_email(body.email)
		except ValueError as error:
			raise HTTPException(status_code=400, detail=str(error)) from error

		if normalized is not None:
			existing = db.scalar(
				select(models.Master).where(
					models.Master.email == normalized,
					models.Master.id != master.id,
				)
			)
			if existing is not None:
				raise HTTPException(status_code=400, detail="Email уже занят")
		master.email = normalized

	db.add(master)
	db.commit()
	db.refresh(master)
	_refresh_master_stats(db, master)
	return _master_profile_schema(master)


@router.post("/profile/avatar", response_model=MasterProfileSchema)
async def upload_profile_avatar(
	file: UploadFile = File(...),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	content_type = (file.content_type or "").lower()
	allowed = {
		"image/jpeg": ".jpg",
		"image/jpg": ".jpg",
		"image/png": ".png",
		"image/webp": ".webp",
	}
	extension = allowed.get(content_type)
	if extension is None:
		filename = (file.filename or "").lower()
		if filename.endswith(".png"):
			extension = ".png"
		elif filename.endswith(".webp"):
			extension = ".webp"
		elif filename.endswith(".jpg") or filename.endswith(".jpeg"):
			extension = ".jpg"
		else:
			raise HTTPException(status_code=400, detail="Допустимы только JPEG, PNG или WebP")

	payload = await file.read()
	if not payload:
		raise HTTPException(status_code=400, detail="Пустой файл")
	if len(payload) > 5 * 1024 * 1024:
		raise HTTPException(status_code=400, detail="Файл больше 5 МБ")

	avatars_dir = uploads_root() / "avatars"
	avatars_dir.mkdir(parents=True, exist_ok=True)
	relative_path = f"avatars/master_{master.id}_{uuid4().hex}{extension}"
	target = uploads_root() / relative_path
	target.write_bytes(payload)

	previous = master.avatar_path
	master.avatar_path = relative_path
	db.add(master)
	db.commit()
	db.refresh(master)

	if previous and previous != relative_path:
		_delete_avatar_file(previous)

	return _master_profile_schema(master)


@router.delete("/profile/avatar", response_model=MasterProfileSchema)
async def delete_profile_avatar(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	previous = master.avatar_path
	master.avatar_path = None
	db.add(master)
	db.commit()
	db.refresh(master)
	_delete_avatar_file(previous)
	return _master_profile_schema(master)


@router.get("/dashboard/stats", response_model=DashboardStatsSchema)
async def get_dashboard_stats(
	year: int = Query(default=2026),
	month: int = Query(default=7, ge=1, le=12),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> DashboardStatsSchema:
	if year < 2000 or year > 2100:
		raise HTTPException(status_code=400, detail="Invalid year")

	protected_income, prevented_no_shows, completed_checks = _dashboard_metrics(
		db, master.id, year, month
	)
	prev_year, prev_month = _previous_month(year, month)
	prev_income, prev_no_shows, prev_checks = _dashboard_metrics(
		db, master.id, prev_year, prev_month
	)

	return DashboardStatsSchema(
		period_label=_period_label(year, month),
		protected_income=protected_income,
		income_trend_label=_percent_trend_label(protected_income, prev_income, prev_month),
		income_trend_positive=protected_income >= prev_income,
		sparkline_values=_sparkline_values(db, master.id, year, month),
		prevented_no_shows=prevented_no_shows,
		no_shows_trend_label=_count_trend_label(prevented_no_shows, prev_no_shows, prev_month),
		completed_checks=completed_checks,
		checks_trend_label=_count_trend_label(completed_checks, prev_checks, prev_month),
	)


@router.get("/dashboard/periods", response_model=list[DashboardPeriodSchema])
async def get_dashboard_periods(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[DashboardPeriodSchema]:
	period_keys: set[tuple[int, int]] = set()

	appointment_periods = db.execute(
		select(
			extract("year", models.Appointment.scheduled_at),
			extract("month", models.Appointment.scheduled_at),
		)
		.where(models.Appointment.master_id == master.id)
		.distinct()
	).all()
	for year_value, month_value in appointment_periods:
		period_keys.add((int(year_value), int(month_value)))

	check_periods = db.execute(
		select(
			extract("year", models.CheckHistoryRecord.checked_at),
			extract("month", models.CheckHistoryRecord.checked_at),
		)
		.where(models.CheckHistoryRecord.master_id == master.id)
		.distinct()
	).all()
	for year_value, month_value in check_periods:
		period_keys.add((int(year_value), int(month_value)))

	now = datetime.now(timezone.utc)
	cursor = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
	for _ in range(6):
		period_keys.add((cursor.year, cursor.month))
		prev_year, prev_month = _previous_month(cursor.year, cursor.month)
		cursor = datetime(prev_year, prev_month, 1, tzinfo=timezone.utc)

	sorted_periods = sorted(period_keys, key=lambda item: (item[0], item[1]), reverse=True)
	return [
		DashboardPeriodSchema(year=year, month=month, label=_period_label(year, month))
		for year, month in sorted_periods
	]


@router.get("/master/services", response_model=list[MasterServiceSchema])
async def list_services(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[MasterServiceSchema]:
	services = db.scalars(
		select(models.MasterService)
		.where(
			or_(
				models.MasterService.master_id == master.id,
				models.MasterService.master_id.is_(None),
			)
		)
		.order_by(models.MasterService.id)
	).all()
	return [
		MasterServiceSchema(
			id=service.id,
			name=service.name,
			duration_label=service.duration_label,
			price=service.price,
			is_owned=service.master_id == master.id,
		)
		for service in services
	]


@router.post("/master/services", response_model=MasterServiceSchema)
async def create_service(
	body: MasterServiceCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterServiceSchema:
	name = body.name.strip()
	duration_label = body.duration_label.strip()
	if len(name) < 2:
		raise HTTPException(status_code=400, detail="Название слишком короткое")
	if not duration_label:
		raise HTTPException(status_code=400, detail="Укажите длительность")
	if body.price < 0:
		raise HTTPException(status_code=400, detail="Цена не может быть отрицательной")

	service = models.MasterService(
		master_id=master.id,
		name=name,
		duration_label=duration_label,
		price=body.price,
	)
	db.add(service)
	db.commit()
	db.refresh(service)
	return MasterServiceSchema(
		id=service.id,
		name=service.name,
		duration_label=service.duration_label,
		price=service.price,
		is_owned=True,
	)


@router.patch("/master/services/{service_id}", response_model=MasterServiceSchema)
async def update_service(
	service_id: int,
	body: MasterServiceUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterServiceSchema:
	service = _get_master_service(db, master.id, service_id)
	payload = body.model_dump(exclude_unset=True)
	if "name" in payload and payload["name"] is not None:
		name = payload["name"].strip()
		if len(name) < 2:
			raise HTTPException(status_code=400, detail="Название слишком короткое")
		payload["name"] = name
	if "duration_label" in payload and payload["duration_label"] is not None:
		duration_label = payload["duration_label"].strip()
		if not duration_label:
			raise HTTPException(status_code=400, detail="Укажите длительность")
		payload["duration_label"] = duration_label
	if "price" in payload and payload["price"] is not None and payload["price"] < 0:
		raise HTTPException(status_code=400, detail="Цена не может быть отрицательной")

	for field, value in payload.items():
		setattr(service, field, value)
	# Claim legacy global services when edited by a master.
	if service.master_id is None:
		service.master_id = master.id
	db.commit()
	db.refresh(service)
	return MasterServiceSchema(
		id=service.id,
		name=service.name,
		duration_label=service.duration_label,
		price=service.price,
		is_owned=service.master_id == master.id,
	)


@router.delete("/master/services/{service_id}")
async def delete_service(
	service_id: int,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> dict[str, bool]:
	service = db.scalar(
		select(models.MasterService).where(
			models.MasterService.id == service_id,
			models.MasterService.master_id == master.id,
		)
	)
	if service is None:
		raise HTTPException(status_code=404, detail="Service not found")
	db.delete(service)
	db.commit()
	return {"ok": True}


@router.get("/appointments", response_model=list[AppointmentSchema])
async def list_appointments(
	from_: datetime | None = Query(default=None, alias="from"),
	to: datetime | None = Query(default=None),
	limit: int = Query(default=100, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[AppointmentSchema]:
	filters = [models.Appointment.master_id == master.id]
	if from_ is not None:
		filters.append(models.Appointment.scheduled_at >= from_)
	if to is not None:
		filters.append(models.Appointment.scheduled_at <= to)

	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(and_(*filters))
		.order_by(models.Appointment.scheduled_at)
		.offset(offset)
		.limit(limit)
	).unique().all()
	return [_appointment_schema(item) for item in appointments]


@router.get("/appointments/{appointment_id}", response_model=AppointmentSchema)
async def get_appointment(
	appointment_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)
	return _appointment_schema(appointment)


@router.post("/appointments", response_model=AppointmentSchema)
async def create_appointment(
	body: AppointmentCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	external_id = f"appointment-{int(datetime.now(timezone.utc).timestamp())}"
	appointment = models.Appointment(
		external_id=external_id,
		master_id=master.id,
		client_name=body.client_name,
		client_phone_digits=body.client_phone_digits,
		service_name=body.service_name,
		service_duration_label=body.service_duration_label,
		scheduled_at=body.scheduled_at,
		service_price=body.service_price,
		client_rating=body.client_rating,
		risk_level=body.risk_level,
		days_since_verified=body.days_since_verified,
	)
	db.add(appointment)
	db.commit()
	db.refresh(appointment)
	return _appointment_schema(appointment)


@router.patch("/appointments/{appointment_id}", response_model=AppointmentSchema)
async def update_appointment(
	appointment_id: str,
	body: AppointmentUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)

	for field, value in body.model_dump(exclude_unset=True).items():
		setattr(appointment, field, value)

	db.commit()
	db.refresh(appointment)
	return _appointment_schema(appointment)


@router.delete("/appointments/{appointment_id}")
async def delete_appointment(
	appointment_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> dict[str, bool]:
	appointment = _get_master_appointment(db, master.id, appointment_id)
	if appointment.visit_result is not None:
		db.delete(appointment.visit_result)
	db.delete(appointment)
	db.commit()
	return {"ok": True}


@router.post("/appointments/{appointment_id}/visit-result", response_model=AppointmentSchema)
async def save_visit_result(
	appointment_id: str,
	body: VisitResultSchema,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)

	if appointment.visit_result:
		visit_result = appointment.visit_result
		visit_result.punctuality = body.punctuality
		visit_result.paid_in_full = body.paid_in_full
		visit_result.had_scandal = body.had_scandal
		visit_result.left_tips = body.left_tips
		visit_result.comment = body.comment
	else:
		appointment.visit_result = models.VisitResult(
			punctuality=body.punctuality,
			paid_in_full=body.paid_in_full,
			had_scandal=body.had_scandal,
			left_tips=body.left_tips,
			comment=body.comment,
		)

	db.commit()
	db.refresh(appointment)
	return _appointment_schema(appointment)


@router.post(
	"/clients/check",
	response_model=ClientCheckResponse,
	dependencies=[Depends(rate_limit_client_check)],
)
async def check_client(
	body: PhoneCheckRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> ClientCheckResponse:
	digits = "".join(char for char in body.phone if char.isdigit())
	if len(digits) == 11 and digits.startswith("7"):
		digits = digits[1:]
	if len(digits) != 10:
		raise HTTPException(status_code=400, detail="Invalid phone number")

	profile = db.scalar(
		select(models.ClientProfile)
		.options(joinedload(models.ClientProfile.reviews))
		.where(models.ClientProfile.phone_digits == digits)
	)
	if profile is None:
		raise HTTPException(status_code=404, detail="Client not found")

	now = datetime.now(timezone.utc)
	db.add(
		models.CheckHistoryRecord(
			external_id=f"check-{int(now.timestamp() * 1000)}",
			master_id=master.id,
			client_name=profile.client_name,
			phone_digits=profile.phone_digits,
			rating=profile.reviews_average,
			risk_level=_risk_level_from_rating(profile.reviews_average),
			checked_at=now,
		)
	)
	db.commit()

	return ClientCheckResponse(
		client_name=profile.client_name,
		profile=_profile_schema(profile),
	)


@router.get("/checks/history", response_model=list[CheckHistoryRecordSchema])
async def list_check_history(
	filter: str = Query(default="all"),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CheckHistoryRecordSchema]:
	if filter not in {"all", "reliable", "risky"}:
		raise HTTPException(status_code=400, detail="Invalid filter")

	filters = [models.CheckHistoryRecord.master_id == master.id]
	if filter == "reliable":
		filters.append(models.CheckHistoryRecord.rating >= 4)
	elif filter == "risky":
		filters.append(models.CheckHistoryRecord.rating < 3.5)

	records = db.scalars(
		select(models.CheckHistoryRecord)
		.where(and_(*filters))
		.order_by(models.CheckHistoryRecord.checked_at.desc())
	).all()
	return [
		CheckHistoryRecordSchema(
			id=record.external_id,
			client_name=record.client_name,
			phone_digits=record.phone_digits,
			rating=record.rating,
			risk_level=record.risk_level,
			checked_at=record.checked_at,
		)
		for record in records
	]


@router.get("/community/topics", response_model=list[CommunityTopicSchema])
async def list_topics(
	q: str = "",
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityTopicSchema]:
	_ = master
	topics = db.scalars(select(models.CommunityTopic).order_by(models.CommunityTopic.last_message_at.desc())).all()
	result = []
	for topic in topics:
		if q and q.lower() not in topic.title.lower() and q.lower() not in topic.last_message.lower():
			continue
		result.append(
			CommunityTopicSchema(
				id=topic.external_id,
				title=topic.title,
				author_name=topic.author_name,
				created_at=topic.created_at,
				participant_count=topic.participant_count,
				last_message=topic.last_message,
				last_message_at=topic.last_message_at,
				participant_initials=[item.strip() for item in topic.participant_initials.split(",") if item.strip()],
				unread_count=topic.unread_count,
				is_pinned=topic.is_pinned,
				emoji=topic.emoji,
			)
		)
	return result


@router.post("/community/topics", response_model=CommunityTopicSchema)
async def create_topic(
	body: CommunityTopicCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityTopicSchema:
	now = datetime.now(timezone.utc)
	external_id = f"topic-{int(now.timestamp())}"
	author_name = master.first_name
	author_initial = _initials(author_name)
	topic = models.CommunityTopic(
		external_id=external_id,
		title=body.title.strip(),
		author_name=author_name,
		emoji="✨",
		participant_count=1,
		participant_initials=author_initial,
		last_message=body.story.strip(),
		last_message_at=now,
	)
	db.add(topic)
	db.flush()
	db.add(
		models.CommunityMessage(
			external_id=f"m-{int(now.timestamp())}",
			topic_id=topic.id,
			author_name=author_name,
			text=body.story.strip(),
			sent_at=now,
			is_mine=True,
		)
	)
	db.commit()
	db.refresh(topic)
	return CommunityTopicSchema(
		id=topic.external_id,
		title=topic.title,
		author_name=topic.author_name,
		created_at=topic.created_at,
		participant_count=topic.participant_count,
		last_message=topic.last_message,
		last_message_at=topic.last_message_at,
		participant_initials=[author_initial],
		unread_count=0,
		is_pinned=False,
		emoji=topic.emoji,
	)


@router.get("/community/topics/{topic_id}/messages", response_model=list[CommunityMessageSchema])
async def list_topic_messages(
	topic_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityMessageSchema]:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")

	messages = db.scalars(
		select(models.CommunityMessage)
		.where(models.CommunityMessage.topic_id == topic.id)
		.order_by(models.CommunityMessage.sent_at)
	).all()
	return [
		CommunityMessageSchema(
			id=message.external_id,
			topic_id=topic_id,
			author_name=message.author_name,
			text=message.text,
			sent_at=message.sent_at,
			is_mine=message.author_name == master.first_name,
		)
		for message in messages
	]


@router.post("/community/topics/{topic_id}/messages", response_model=CommunityMessageSchema)
async def send_topic_message(
	topic_id: str,
	body: CommunityMessageCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityMessageSchema:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")

	now = datetime.now(timezone.utc)
	message = models.CommunityMessage(
		external_id=f"m-{int(now.timestamp())}",
		topic_id=topic.id,
		author_name=master.first_name,
		text=body.text.strip(),
		sent_at=now,
		is_mine=True,
	)
	topic.last_message = body.text.strip()
	topic.last_message_at = now
	db.add(message)
	db.commit()
	return CommunityMessageSchema(
		id=message.external_id,
		topic_id=topic_id,
		author_name=message.author_name,
		text=message.text,
		sent_at=message.sent_at,
		is_mine=True,
	)


@router.get("/support/tickets", response_model=list[SupportTicketSchema])
async def list_support_tickets(
	q: str = "",
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[SupportTicketSchema]:
	tickets = db.scalars(
		select(models.SupportTicket)
		.where(models.SupportTicket.master_id == master.id)
		.order_by(models.SupportTicket.last_message_at.desc())
	).all()
	result = []
	for ticket in tickets:
		if q and q.lower() not in ticket.title.lower() and q.lower() not in ticket.last_message.lower():
			continue
		result.append(
			SupportTicketSchema(
				id=ticket.external_id,
				title=ticket.title,
				author_name=ticket.author_name,
				created_at=ticket.created_at,
				last_message=ticket.last_message,
				last_message_at=ticket.last_message_at,
				status=ticket.status,
				unread_count=ticket.unread_count,
			)
		)
	return result


@router.post("/support/tickets", response_model=SupportTicketSchema)
async def create_support_ticket(
	body: SupportTicketCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SupportTicketSchema:
	now = datetime.now(timezone.utc)
	external_id = f"support-{int(now.timestamp())}"
	ticket = models.SupportTicket(
		external_id=external_id,
		master_id=master.id,
		title=body.title.strip(),
		author_name=master.first_name,
		status="new",
		last_message=body.description.strip(),
		last_message_at=now,
	)
	db.add(ticket)
	db.flush()
	db.add(
		models.SupportMessage(
			external_id=f"s-{int(now.timestamp())}",
			ticket_id=ticket.id,
			author_name=ticket.author_name,
			text=body.description.strip(),
			sent_at=now,
			is_mine=True,
		)
	)
	db.commit()
	db.refresh(ticket)
	_add_support_admin_reply(db, ticket)
	return SupportTicketSchema(
		id=ticket.external_id,
		title=ticket.title,
		author_name=ticket.author_name,
		created_at=ticket.created_at,
		last_message=ticket.last_message,
		last_message_at=ticket.last_message_at,
		status=ticket.status,
		unread_count=ticket.unread_count,
	)


@router.get("/support/tickets/{ticket_id}/messages", response_model=list[CommunityMessageSchema])
async def list_support_messages(
	ticket_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityMessageSchema]:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)

	messages = db.scalars(
		select(models.SupportMessage)
		.where(models.SupportMessage.ticket_id == ticket.id)
		.order_by(models.SupportMessage.sent_at)
	).all()
	return [
		CommunityMessageSchema(
			id=message.external_id,
			topic_id=ticket_id,
			author_name=message.author_name,
			text=message.text,
			sent_at=message.sent_at,
			is_mine=message.is_mine,
		)
		for message in messages
	]


def _add_support_admin_reply(db: Session, ticket: models.SupportTicket) -> None:
	if ticket.status in {"closed", "cancelled"}:
		return

	now = datetime.now(timezone.utc)
	reply_text = "Спасибо за обращение! Мы уже смотрим ваш вопрос и скоро вернёмся с ответом."
	reply = models.SupportMessage(
		external_id=f"s-admin-{int(now.timestamp())}",
		ticket_id=ticket.id,
		author_name="Техподдержка",
		text=reply_text,
		sent_at=now,
		is_mine=False,
	)
	ticket.last_message = reply_text
	ticket.last_message_at = now
	ticket.status = "in_progress"
	ticket.unread_count += 1
	db.add(reply)
	db.commit()


@router.post("/support/tickets/{ticket_id}/messages", response_model=CommunityMessageSchema)
async def send_support_message(
	ticket_id: str,
	body: SupportMessageCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityMessageSchema:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)
	if ticket.status in {"closed", "cancelled"}:
		raise HTTPException(status_code=400, detail="Ticket is closed")

	now = datetime.now(timezone.utc)
	message = models.SupportMessage(
		external_id=f"s-{int(now.timestamp())}",
		ticket_id=ticket.id,
		author_name=master.first_name,
		text=body.text.strip(),
		sent_at=now,
		is_mine=True,
	)
	ticket.last_message = body.text.strip()
	ticket.last_message_at = now
	ticket.status = "waiting_for_response"
	db.add(message)
	db.commit()
	_add_support_admin_reply(db, ticket)
	return CommunityMessageSchema(
		id=message.external_id,
		topic_id=ticket_id,
		author_name=message.author_name,
		text=message.text,
		sent_at=message.sent_at,
		is_mine=True,
	)


@router.post("/support/tickets/{ticket_id}/cancel", response_model=SupportTicketSchema)
async def cancel_support_ticket(
	ticket_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SupportTicketSchema:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)

	ticket.status = "cancelled"
	db.commit()
	db.refresh(ticket)
	return SupportTicketSchema(
		id=ticket.external_id,
		title=ticket.title,
		author_name=ticket.author_name,
		created_at=ticket.created_at,
		last_message=ticket.last_message,
		last_message_at=ticket.last_message_at,
		status=ticket.status,
		unread_count=ticket.unread_count,
	)
