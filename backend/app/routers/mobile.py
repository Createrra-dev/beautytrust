from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.config import settings
from app.db import models
from app.db.session import get_db
from app.deps.auth import get_current_master
from app.deps.rate_limit import rate_limit_client_check
from app.schemas.api import (
	AppointmentCreateRequest,
	AppointmentSchema,
	AppointmentUpdateRequest,
	ClientCheckResponse,
	ClientProfileSchema,
	CommunityMessageCreateRequest,
	CommunityMessageSchema,
	CommunityTopicCreateRequest,
	CommunityTopicSchema,
	DashboardStatsSchema,
	MasterProfileSchema,
	MasterReviewSchema,
	MasterServiceSchema,
	PhoneCheckRequest,
	SupportMessageCreateRequest,
	SupportTicketCreateRequest,
	SupportTicketSchema,
	VisitResultSchema,
)

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


@router.get("/health")
async def api_health() -> dict[str, str]:
	return {"status": "ok", "service": "beautytrust-api"}


@router.get("/profile", response_model=MasterProfileSchema)
async def get_profile(master: models.Master = Depends(get_current_master)) -> MasterProfileSchema:
	avatar_url = None
	if master.avatar_path:
		avatar_url = f"{settings.public_base_url.rstrip('/')}/uploads/{master.avatar_path}"

	return MasterProfileSchema(
		first_name=master.first_name,
		badge_label=master.badge_label,
		rating=master.rating,
		reviews_count=master.reviews_count,
		clients_count=master.clients_count,
		prevented_no_shows=master.prevented_no_shows,
		protected_income=master.protected_income,
		tariff_label=master.tariff_label,
		avatar_url=avatar_url,
		email=master.email,
		phone_digits=master.phone_digits,
	)


@router.get("/dashboard/stats", response_model=DashboardStatsSchema)
async def get_dashboard_stats(
	year: int = Query(default=2026),
	month: int = Query(default=7),
	master: models.Master = Depends(get_current_master),
) -> DashboardStatsSchema:
	_ = (year, month, master)
	return DashboardStatsSchema(
		period_label="Июль 2026",
		protected_income=master.protected_income or 0,
		income_trend_label="+18% к июню",
		income_trend_positive=True,
		sparkline_values=[0.4, 0.45, 0.5, 0.48, 0.58, 0.62, 0.7, 0.68, 0.8, 0.86, 0.92, 1.0],
		prevented_no_shows=master.prevented_no_shows or 0,
		no_shows_trend_label="-2 к июню",
		completed_checks=268,
		checks_trend_label="+24 к июню",
	)


@router.get("/master/services", response_model=list[MasterServiceSchema])
async def list_services(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[MasterServiceSchema]:
	_ = master
	services = db.scalars(select(models.MasterService).order_by(models.MasterService.id)).all()
	return [
		MasterServiceSchema(
			id=service.id,
			name=service.name,
			duration_label=service.duration_label,
			price=service.price,
		)
		for service in services
	]


@router.get("/appointments", response_model=list[AppointmentSchema])
async def list_appointments(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[AppointmentSchema]:
	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(models.Appointment.master_id == master.id)
		.order_by(models.Appointment.scheduled_at)
	).unique().all()
	return [_appointment_schema(item) for item in appointments]


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
	_ = master
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

	return ClientCheckResponse(
		client_name=profile.client_name,
		profile=_profile_schema(profile),
	)


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
