"""Ensure payment_attempts indexes on Postgres

Revision ID: 0007_payment_attempts_indexes
Revises: 0006_master_registration_fields
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0007_payment_attempts_indexes"
down_revision = "0006_master_registration_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	indexes = {index["name"] for index in inspector.get_indexes("payment_attempts")}

	if "ix_payment_attempts_payment_id" not in indexes:
		op.create_index(
			"ix_payment_attempts_payment_id",
			"payment_attempts",
			["payment_id"],
			unique=False,
		)
	if "ix_payment_attempts_order_id" not in indexes:
		op.create_index(
			"ix_payment_attempts_order_id",
			"payment_attempts",
			["order_id"],
			unique=False,
		)
	if "ix_payment_attempts_created_at" not in indexes:
		op.create_index(
			"ix_payment_attempts_created_at",
			"payment_attempts",
			["created_at"],
			unique=False,
		)


def downgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	indexes = {index["name"] for index in inspector.get_indexes("payment_attempts")}

	if "ix_payment_attempts_created_at" in indexes:
		op.drop_index("ix_payment_attempts_created_at", table_name="payment_attempts")
	if "ix_payment_attempts_order_id" in indexes:
		op.drop_index("ix_payment_attempts_order_id", table_name="payment_attempts")
	if "ix_payment_attempts_payment_id" in indexes:
		op.drop_index("ix_payment_attempts_payment_id", table_name="payment_attempts")
