"""YClients integration fields

Revision ID: 0015_yclients
Revises: 0014_visit_behavior
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0015_yclients"
down_revision = "0014_visit_behavior"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"masters",
		sa.Column("yclients_enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column("masters", sa.Column("yclients_partner_token", sa.String(200), nullable=True))
	op.add_column("masters", sa.Column("yclients_company_id", sa.String(20), nullable=True))
	op.add_column("masters", sa.Column("yclients_form_id", sa.String(20), nullable=True))
	op.add_column("masters", sa.Column("yclients_user_token", sa.String(200), nullable=True))
	op.add_column("masters", sa.Column("yclients_login", sa.String(200), nullable=True))
	op.add_column("masters", sa.Column("yclients_last_sync_at", sa.DateTime(timezone=True), nullable=True))
	op.add_column(
		"masters",
		sa.Column("yclients_last_sync_count", sa.Integer(), nullable=False, server_default="0"),
	)

	op.add_column(
		"appointments",
		sa.Column("source", sa.String(20), nullable=False, server_default="manual"),
	)
	op.add_column("appointments", sa.Column("yclients_record_id", sa.String(50), nullable=True))
	op.add_column("appointments", sa.Column("yclients_staff_name", sa.String(120), nullable=True))
	op.create_index(
		"ix_appointments_yclients_record",
		"appointments",
		["master_id", "yclients_record_id"],
		unique=True,
	)

	op.alter_column("masters", "yclients_enabled", server_default=None)
	op.alter_column("masters", "yclients_last_sync_count", server_default=None)
	op.alter_column("appointments", "source", server_default=None)


def downgrade() -> None:
	op.drop_index("ix_appointments_yclients_record", table_name="appointments")
	op.drop_column("appointments", "yclients_staff_name")
	op.drop_column("appointments", "yclients_record_id")
	op.drop_column("appointments", "source")
	op.drop_column("masters", "yclients_last_sync_count")
	op.drop_column("masters", "yclients_last_sync_at")
	op.drop_column("masters", "yclients_login")
	op.drop_column("masters", "yclients_user_token")
	op.drop_column("masters", "yclients_form_id")
	op.drop_column("masters", "yclients_company_id")
	op.drop_column("masters", "yclients_partner_token")
	op.drop_column("masters", "yclients_enabled")
