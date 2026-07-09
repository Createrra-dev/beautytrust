from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Master(Base):
	__tablename__ = "masters"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	first_name: Mapped[str] = mapped_column(String(120), nullable=False)
	badge_label: Mapped[str] = mapped_column(String(120), nullable=False)
	rating: Mapped[float] = mapped_column(Float, nullable=False, default=4.8)
	reviews_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	clients_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	prevented_no_shows: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	protected_income: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	tariff_label: Mapped[str] = mapped_column(String(120), nullable=False, default="Бесплатно")
	tariff_plan_id: Mapped[str | None] = mapped_column(
		ForeignKey("tariff_plans.id"),
		nullable=True,
		index=True,
	)
	tariff_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
	avatar_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
	onboarding_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	settings_json: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
	yclients_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	yclients_partner_token: Mapped[str | None] = mapped_column(String(200), nullable=True)
	yclients_company_id: Mapped[str | None] = mapped_column(String(20), nullable=True)
	yclients_user_token: Mapped[str | None] = mapped_column(String(200), nullable=True)
	yclients_login: Mapped[str | None] = mapped_column(String(200), nullable=True)
	yclients_auth_uuid: Mapped[str | None] = mapped_column(String(100), nullable=True)
	yclients_auth_recipient: Mapped[str | None] = mapped_column(String(120), nullable=True)
	yclients_last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
	yclients_last_sync_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	yclients_sync_interval_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=15)
	phone_digits: Mapped[str | None] = mapped_column(String(10), nullable=True, unique=True, index=True)
	email: Mapped[str | None] = mapped_column(String(255), nullable=True, unique=True, index=True)
	password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
	telegram_chat_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True, unique=True, index=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

	tariff_plan: Mapped["TariffPlan | None"] = relationship(back_populates="masters")


class MasterService(Base):
	__tablename__ = "master_services"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	name: Mapped[str] = mapped_column(String(200), nullable=False)
	duration_label: Mapped[str] = mapped_column(String(50), nullable=False)
	price: Mapped[int] = mapped_column(Integer, nullable=False)


class ClientProfile(Base):
	__tablename__ = "client_profiles"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	phone_digits: Mapped[str] = mapped_column(String(10), nullable=False, unique=True, index=True)
	client_name: Mapped[str] = mapped_column(String(120), nullable=False)
	rating_label: Mapped[str] = mapped_column(String(50), nullable=False)
	reviews_average: Mapped[float] = mapped_column(Float, nullable=False)
	reviews_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	no_shows_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	scandals_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	reliability_title: Mapped[str] = mapped_column(String(200), nullable=False)
	reliability_subtitle: Mapped[str] = mapped_column(String(200), nullable=False)

	reviews: Mapped[list["MasterReview"]] = relationship(back_populates="client_profile")


class MasterReview(Base):
	__tablename__ = "master_reviews"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	client_profile_id: Mapped[int] = mapped_column(ForeignKey("client_profiles.id"), index=True)
	master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	appointment_id: Mapped[int | None] = mapped_column(ForeignKey("appointments.id"), nullable=True, unique=True, index=True)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	rating: Mapped[float] = mapped_column(Float, nullable=False)
	text: Mapped[str] = mapped_column(Text, nullable=False)
	review_month: Mapped[int] = mapped_column(Integer, nullable=False)
	review_year: Mapped[int] = mapped_column(Integer, nullable=False)

	client_profile: Mapped[ClientProfile] = relationship(back_populates="reviews")


class MasterReceivedReview(Base):
	__tablename__ = "master_received_reviews"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	rating: Mapped[float] = mapped_column(Float, nullable=False)
	text: Mapped[str] = mapped_column(Text, nullable=False)
	review_month: Mapped[int] = mapped_column(Integer, nullable=False)
	review_year: Mapped[int] = mapped_column(Integer, nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Appointment(Base):
	__tablename__ = "appointments"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	client_name: Mapped[str] = mapped_column(String(120), nullable=False)
	client_phone_digits: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
	service_name: Mapped[str] = mapped_column(String(200), nullable=False)
	service_duration_label: Mapped[str] = mapped_column(String(50), nullable=False)
	scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	service_price: Mapped[int] = mapped_column(Integer, nullable=False)
	client_rating: Mapped[float] = mapped_column(Float, nullable=False)
	risk_level: Mapped[str] = mapped_column(String(20), nullable=False)
	status: Mapped[str] = mapped_column(String(20), nullable=False, default="scheduled")
	days_since_verified: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	source: Mapped[str] = mapped_column(String(20), nullable=False, default="manual")
	yclients_record_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
	yclients_staff_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
	yclients_staff_avatar_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
	yclients_staff_avatar_source_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

	visit_result: Mapped["VisitResult | None"] = relationship(
		back_populates="appointment",
		uselist=False,
		cascade="all, delete-orphan",
	)


class VisitResult(Base):
	__tablename__ = "visit_results"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	appointment_id: Mapped[int] = mapped_column(ForeignKey("appointments.id"), unique=True)
	punctuality: Mapped[str] = mapped_column(String(30), nullable=False)
	paid_in_full: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	had_behavior_issues: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	was_unfriendly: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	had_scandal: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	threatened_complaints: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	demanded_discount: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	stole_from_salon: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	left_tips: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	comment: Mapped[str | None] = mapped_column(Text, nullable=True)

	appointment: Mapped[Appointment] = relationship(back_populates="visit_result")


class CommunityTopic(Base):
	__tablename__ = "community_topics"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	title: Mapped[str] = mapped_column(String(300), nullable=False)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	author_master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	emoji: Mapped[str] = mapped_column(String(10), nullable=False, default="💬")
	is_pinned: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	is_closed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	participant_count: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
	participant_initials: Mapped[str] = mapped_column(String(100), nullable=False, default="")
	last_message: Mapped[str] = mapped_column(Text, nullable=False, default="")
	last_message_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	unread_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

	messages: Mapped[list["CommunityMessage"]] = relationship(back_populates="topic")


class CommunityMessage(Base):
	__tablename__ = "community_messages"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	topic_id: Mapped[int] = mapped_column(ForeignKey("community_topics.id"), index=True)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	author_master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	text: Mapped[str] = mapped_column(Text, nullable=False)
	is_mine: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

	topic: Mapped[CommunityTopic] = relationship(back_populates="messages")


class CommunityTopicRead(Base):
	__tablename__ = "community_topic_reads"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	topic_id: Mapped[int] = mapped_column(ForeignKey("community_topics.id"), index=True)
	last_read_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class SupportTicket(Base):
	__tablename__ = "support_tickets"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	title: Mapped[str] = mapped_column(String(300), nullable=False)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	status: Mapped[str] = mapped_column(String(30), nullable=False, default="new")
	last_message: Mapped[str] = mapped_column(Text, nullable=False, default="")
	last_message_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	unread_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

	messages: Mapped[list["SupportMessage"]] = relationship(back_populates="ticket")


class SupportMessage(Base):
	__tablename__ = "support_messages"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	ticket_id: Mapped[int] = mapped_column(ForeignKey("support_tickets.id"), index=True)
	author_name: Mapped[str] = mapped_column(String(120), nullable=False)
	text: Mapped[str] = mapped_column(Text, nullable=False)
	is_mine: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	attachment_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
	attachment_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
	sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

	ticket: Mapped[SupportTicket] = relationship(back_populates="messages")


class DeviceToken(Base):
	__tablename__ = "device_tokens"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	token: Mapped[str] = mapped_column(String(512), nullable=False, unique=True)
	platform: Mapped[str] = mapped_column(String(20), nullable=False, default="ios")
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
	updated_at: Mapped[datetime] = mapped_column(
		DateTime(timezone=True),
		server_default=func.now(),
		onupdate=func.now(),
	)


class AppNotification(Base):
	__tablename__ = "notifications"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	title: Mapped[str] = mapped_column(String(200), nullable=False)
	body: Mapped[str] = mapped_column(Text, nullable=False)
	kind: Mapped[str] = mapped_column(String(50), nullable=False, default="general")
	payload_json: Mapped[str | None] = mapped_column(Text, nullable=True)
	is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class AuditLog(Base):
	__tablename__ = "audit_logs"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	method: Mapped[str] = mapped_column(String(10), nullable=False)
	path: Mapped[str] = mapped_column(String(500), nullable=False)
	status_code: Mapped[int] = mapped_column(Integer, nullable=False)
	entity_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
	entity_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
	details_json: Mapped[str | None] = mapped_column(Text, nullable=True)
	ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
	request_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)


class OtpSession(Base):
	__tablename__ = "otp_sessions"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	session_token: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
	phone_digits: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
	otp_code: Mapped[str] = mapped_column(String(8), nullable=False)
	delivery_channel: Mapped[str] = mapped_column(String(20), nullable=False, default="telegram")
	zvonok_call_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
	registration_first_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
	registration_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
	registration_password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
	telegram_chat_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True, index=True)
	delivered: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class PhoneTelegramLink(Base):
	__tablename__ = "phone_telegram_links"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	phone_digits: Mapped[str] = mapped_column(String(10), nullable=False, unique=True, index=True)
	telegram_chat_id: Mapped[int] = mapped_column(BigInteger, nullable=False, unique=True, index=True)
	updated_at: Mapped[datetime] = mapped_column(
		DateTime(timezone=True),
		server_default=func.now(),
		onupdate=func.now(),
	)


class CheckHistoryRecord(Base):
	__tablename__ = "check_history_records"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	external_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	client_name: Mapped[str] = mapped_column(String(120), nullable=False)
	phone_digits: Mapped[str] = mapped_column(String(10), nullable=False)
	rating: Mapped[float] = mapped_column(Float, nullable=False)
	risk_level: Mapped[str] = mapped_column(String(20), nullable=False)
	checked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class TariffPlan(Base):
	__tablename__ = "tariff_plans"

	id: Mapped[str] = mapped_column(String(50), primary_key=True)
	title: Mapped[str] = mapped_column(String(120), nullable=False)
	monthly_price: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	trial_label: Mapped[str] = mapped_column(String(120), nullable=False, default="")
	features_json: Mapped[str] = mapped_column(Text, nullable=False, default="[]")
	card_button_label: Mapped[str] = mapped_column(String(120), nullable=False, default="Выбрать тариф")
	audience: Mapped[str] = mapped_column(String(20), nullable=False, default="masters")
	is_popular: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

	masters: Mapped[list["Master"]] = relationship(back_populates="tariff_plan")
	subscription_payments: Mapped[list["SubscriptionPayment"]] = relationship(back_populates="tariff_plan")


class PaymentAttempt(Base):
	__tablename__ = "payment_attempts"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	payment_id: Mapped[str | None] = mapped_column(String(100), index=True)
	order_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
	amount: Mapped[int] = mapped_column(Integer, nullable=False)
	description: Mapped[str] = mapped_column(Text, nullable=False)
	status: Mapped[str] = mapped_column(String(50), nullable=False, default="CREATED")
	success: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
	payment_url: Mapped[str | None] = mapped_column(Text, nullable=True)
	return_result: Mapped[str | None] = mapped_column(String(50), nullable=True)
	last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
	tbank_response: Mapped[str | None] = mapped_column(Text, nullable=True)
	master_id: Mapped[int | None] = mapped_column(ForeignKey("masters.id"), nullable=True, index=True)
	tariff_plan_id: Mapped[str | None] = mapped_column(ForeignKey("tariff_plans.id"), nullable=True, index=True)
	months: Mapped[int | None] = mapped_column(Integer, nullable=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
	updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class SubscriptionPayment(Base):
	__tablename__ = "subscription_payments"

	id: Mapped[int] = mapped_column(Integer, primary_key=True)
	master_id: Mapped[int] = mapped_column(ForeignKey("masters.id"), index=True)
	tariff_plan_id: Mapped[str] = mapped_column(ForeignKey("tariff_plans.id"), index=True)
	payment_attempt_id: Mapped[int | None] = mapped_column(ForeignKey("payment_attempts.id"), nullable=True, index=True)
	months: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
	amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
	status: Mapped[str] = mapped_column(String(50), nullable=False, default="pending")
	activated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
	expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

	tariff_plan: Mapped["TariffPlan"] = relationship(back_populates="subscription_payments")
