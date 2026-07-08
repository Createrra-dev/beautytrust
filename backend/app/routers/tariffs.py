from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.db.session import get_db
from app.deps.auth import get_current_master
from app.schemas.api import (
	SubscribeRequest,
	SubscribeResponse,
	SubscriptionSchema,
	TariffPlanSchema,
)
from app.services.payment_service import PaymentService
from app.services.subscription_service import (
	activate_subscription,
	ensure_tariff_plans,
	plan_features,
	quote_amount_kopecks,
	subscription_payload,
)

router = APIRouter(prefix="/api", tags=["tariffs"])
payment_service = PaymentService()


def _plan_schema(plan: models.TariffPlan) -> TariffPlanSchema:
	return TariffPlanSchema(
		id=plan.id,
		title=plan.title,
		monthly_price=plan.monthly_price,
		trial_label=plan.trial_label,
		features=plan_features(plan),
		card_button_label=plan.card_button_label,
		audience=plan.audience,
		is_popular=plan.is_popular,
	)


@router.get("/tariffs", response_model=list[TariffPlanSchema])
async def list_tariffs(
	audience: str | None = Query(default=None),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[TariffPlanSchema]:
	_ = master
	ensure_tariff_plans(db)
	query = select(models.TariffPlan).where(models.TariffPlan.is_active.is_(True))
	if audience:
		query = query.where(models.TariffPlan.audience == audience)
	plans = db.scalars(query.order_by(models.TariffPlan.sort_order, models.TariffPlan.id)).all()
	return [_plan_schema(plan) for plan in plans]


@router.get("/profile/subscription", response_model=SubscriptionSchema)
async def get_subscription(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SubscriptionSchema:
	ensure_tariff_plans(db)
	plan = None
	if master.tariff_plan_id:
		plan = db.get(models.TariffPlan, master.tariff_plan_id)
	payload = subscription_payload(master, plan)
	return SubscriptionSchema(**payload)


@router.post("/tariffs/{plan_id}/subscribe", response_model=SubscribeResponse)
async def subscribe_to_plan(
	plan_id: str,
	body: SubscribeRequest | None = None,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SubscribeResponse:
	ensure_tariff_plans(db)
	plan = db.get(models.TariffPlan, plan_id)
	if plan is None or not plan.is_active:
		raise HTTPException(status_code=404, detail="Тариф не найден")

	months = body.months if body else 1
	amount_kopecks, _, _ = quote_amount_kopecks(plan.monthly_price, months)

	# Free plan — activate immediately.
	if plan.monthly_price <= 0 or amount_kopecks <= 0:
		subscription = activate_subscription(
			db,
			master=master,
			plan=plan,
			months=months,
			amount=0,
			payment_attempt_id=None,
		)
		plan_after = db.get(models.TariffPlan, plan.id)
		return SubscribeResponse(
			payment_id=None,
			payment_url=None,
			order_id=None,
			amount=0,
			months=months,
			plan_id=plan.id,
			activated=True,
			subscription=SubscriptionSchema(**subscription_payload(master, plan_after)),
		)

	if not settings.tbank_configured:
		raise HTTPException(
			status_code=500,
			detail="T-Bank credentials are not configured. Set TBANK_TERMINAL_KEY and TBANK_PASSWORD.",
		)

	return_base_url = (body.return_base_url if body and body.return_base_url else settings.public_base_url).rstrip("/")
	order_id = f"sub-{master.id}-{plan.id}-{uuid4().hex[:10]}"
	description = f"Подписка «{plan.title}» на {months} мес."
	notification_url = f"{settings.public_base_url.rstrip('/')}/api/payments/webhook"

	attempt = payment_service.repository.create_attempt(
		order_id=order_id,
		amount=amount_kopecks,
		description=description,
		status="INIT_PENDING",
		master_id=master.id,
		tariff_plan_id=plan.id,
		months=months,
	)

	try:
		result = await payment_service.init_payment(
			order_id=order_id,
			description=description,
			amount=amount_kopecks,
			success_url=f"{return_base_url}/payments/return/success",
			fail_url=f"{return_base_url}/payments/return/fail",
			notification_url=notification_url,
		)
	except RuntimeError as error:
		payment_service.repository.mark_init_failed(attempt["id"], error_message=str(error))
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

	return SubscribeResponse(
		payment_id=str(payment_id),
		payment_url=str(payment_url),
		order_id=str(result.get("OrderId") or order_id),
		amount=amount_kopecks,
		months=months,
		plan_id=plan.id,
		activated=False,
	)
