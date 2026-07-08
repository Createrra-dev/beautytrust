"""Add tariff plans and subscriptions

Revision ID: 0009_tariff_subscriptions
Revises: 0008_master_services_master_id
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0009_tariff_subscriptions"
down_revision = "0008_master_services_master_id"
branch_labels = None
depends_on = None


def upgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	tables = set(inspector.get_table_names())

	if "tariff_plans" not in tables:
		op.create_table(
			"tariff_plans",
			sa.Column("id", sa.String(length=50), primary_key=True),
			sa.Column("title", sa.String(length=120), nullable=False),
			sa.Column("monthly_price", sa.Integer(), nullable=False, server_default="0"),
			sa.Column("trial_label", sa.String(length=120), nullable=False, server_default=""),
			sa.Column("features_json", sa.Text(), nullable=False, server_default="[]"),
			sa.Column("card_button_label", sa.String(length=120), nullable=False, server_default="Выбрать тариф"),
			sa.Column("audience", sa.String(length=20), nullable=False, server_default="masters"),
			sa.Column("is_popular", sa.Boolean(), nullable=False, server_default=sa.text("false")),
			sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
			sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
		)

	master_columns = {column["name"] for column in inspector.get_columns("masters")}
	if "tariff_plan_id" not in master_columns:
		op.add_column("masters", sa.Column("tariff_plan_id", sa.String(length=50), nullable=True))
		op.create_foreign_key(
			"fk_masters_tariff_plan_id",
			"masters",
			"tariff_plans",
			["tariff_plan_id"],
			["id"],
		)
		op.create_index("ix_masters_tariff_plan_id", "masters", ["tariff_plan_id"])
	if "tariff_expires_at" not in master_columns:
		op.add_column("masters", sa.Column("tariff_expires_at", sa.DateTime(timezone=True), nullable=True))

	payment_columns = {column["name"] for column in inspector.get_columns("payment_attempts")}
	if "master_id" not in payment_columns:
		op.add_column("payment_attempts", sa.Column("master_id", sa.Integer(), nullable=True))
		op.create_foreign_key(
			"fk_payment_attempts_master_id",
			"payment_attempts",
			"masters",
			["master_id"],
			["id"],
		)
		op.create_index("ix_payment_attempts_master_id", "payment_attempts", ["master_id"])
	if "tariff_plan_id" not in payment_columns:
		op.add_column("payment_attempts", sa.Column("tariff_plan_id", sa.String(length=50), nullable=True))
		op.create_foreign_key(
			"fk_payment_attempts_tariff_plan_id",
			"payment_attempts",
			"tariff_plans",
			["tariff_plan_id"],
			["id"],
		)
		op.create_index("ix_payment_attempts_tariff_plan_id", "payment_attempts", ["tariff_plan_id"])
	if "months" not in payment_columns:
		op.add_column("payment_attempts", sa.Column("months", sa.Integer(), nullable=True))

	tables = set(sa.inspect(bind).get_table_names())
	if "subscription_payments" not in tables:
		op.create_table(
			"subscription_payments",
			sa.Column("id", sa.Integer(), primary_key=True),
			sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=False),
			sa.Column("tariff_plan_id", sa.String(length=50), sa.ForeignKey("tariff_plans.id"), nullable=False),
			sa.Column("payment_attempt_id", sa.Integer(), sa.ForeignKey("payment_attempts.id"), nullable=True),
			sa.Column("months", sa.Integer(), nullable=False, server_default="1"),
			sa.Column("amount", sa.Integer(), nullable=False, server_default="0"),
			sa.Column("status", sa.String(length=50), nullable=False, server_default="pending"),
			sa.Column("activated_at", sa.DateTime(timezone=True), nullable=True),
			sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
			sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
		)
		op.create_index("ix_subscription_payments_master_id", "subscription_payments", ["master_id"])
		op.create_index("ix_subscription_payments_tariff_plan_id", "subscription_payments", ["tariff_plan_id"])
		op.create_index("ix_subscription_payments_payment_attempt_id", "subscription_payments", ["payment_attempt_id"])


def downgrade() -> None:
	op.drop_table("subscription_payments")
	op.drop_column("payment_attempts", "months")
	op.drop_constraint("fk_payment_attempts_tariff_plan_id", "payment_attempts", type_="foreignkey")
	op.drop_index("ix_payment_attempts_tariff_plan_id", table_name="payment_attempts")
	op.drop_column("payment_attempts", "tariff_plan_id")
	op.drop_constraint("fk_payment_attempts_master_id", "payment_attempts", type_="foreignkey")
	op.drop_index("ix_payment_attempts_master_id", table_name="payment_attempts")
	op.drop_column("payment_attempts", "master_id")
	op.drop_constraint("fk_masters_tariff_plan_id", "masters", type_="foreignkey")
	op.drop_index("ix_masters_tariff_plan_id", table_name="masters")
	op.drop_column("masters", "tariff_plan_id")
	op.drop_column("masters", "tariff_expires_at")
	op.drop_table("tariff_plans")
